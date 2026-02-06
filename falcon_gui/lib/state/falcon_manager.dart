import 'dart:async';
import 'dart:io';

import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/falcon_log.dart';
import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/model/falcon_zmq_command.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/state/falcon_zmq.dart';
import 'package:falcon_gui/utils/debounce.dart';
import 'package:falcon_gui/utils/file_picker.dart';
import 'package:falcon_gui/utils/killing_falcon_banner.dart';
import 'package:falcon_gui/utils/local_config.dart';
import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/other_falcon_instances_banner.dart';
import 'package:falcon_gui/utils/paths.dart';
import 'package:falcon_gui/utils/status_dialog.dart';
import 'package:flutter/foundation.dart';

final FalconManager falconManager = FalconManager.instance;
const bool _debugUseExistingFalconInstance = true;

class FalconManager extends ChangeNotifier {
  FalconManager._internal() {
    // TODO(ben): load last opened graph from the last session
    unawaited(loadFile(file: _defaultGraphFile));
  }

  static final FalconManager instance = FalconManager._internal();

  File? _currentGraphFile;
  File? get currentGraphFile => _currentGraphFile;
  String? get currentGraphFileName =>
      _currentGraphFile?.path.split(Platform.pathSeparator).last;

  final graphLoadedNotifier = ValueNotifier<FalconGraph?>(null);

  File get _defaultGraphFile =>
      File('$ubuntuHomePath/falcon/resources/graphs/my_graph.yaml')
        ..createSync(recursive: true);

  String get _falconPath {
    return '$ubuntuHomePath/.local/share/org.falcon-eyrie.falcon_gui/bin/falcon';
  }

  final _fileWriteDebounce = Debounce(delay: const Duration(milliseconds: 500));

  Process? _falconProcess;
  FalconZMQ? _falconZMQ;
  Completer<void>? _processExitCompleter;

  PriorityStatus _priorityStatus = PriorityStatus.unknown;

  PriorityStatus get processPriority => _priorityStatus;

  String get processPriorityCommand =>
      'sudo setcap cap_sys_nice=eip $_falconPath';

  List<FalconLog> get logs => _falconZMQ?.logs ?? [];

  bool get isLastLogAnError =>
      logs.isNotEmpty && logs.last.type == FalconLogType.error;

  FalconState get falconState => _falconZMQ?.falconState ?? FalconState.unknown;

  bool get canEditGraph {
    final state = falconState;
    return state != FalconState.processing &&
        state != FalconState.starting &&
        state != FalconState.stopping;
  }

  Future<void> openFile() async {
    final pickedFile = await FalconFilePicker.pickGraphFile();
    if (pickedFile != null) {
      await loadFile(file: pickedFile);
    }
  }

  Future<void> newFile() async {
    final createdFile = await FalconFilePicker.createNewGraphFile();
    if (createdFile != null) {
      await loadFile(file: createdFile);
    }
  }

  Future<void> saveGraphAs() async {
    if (_currentGraphFile == null) {
      return;
    }
    final createdFile = await FalconFilePicker.saveGraphAs(_currentGraphFile!);
    if (createdFile != null) {
      await loadFile(file: createdFile);
    }
  }

  Future<void> loadFile({required File file}) async {
    try {
      final yamlAsString = await file.readAsString();

      try {
        final graph = FalconGraphSerializerX.fromYaml(
          yamlAsString,
        );

        _currentGraphFile = file;
        notifyListeners();

        unawaited(
          LocalConfigManager.setLastOpenedGraphFilePath(file.absolute.path),
        );
        
        graphLoadedNotifier.value = graph;
      } catch (e, s) {
        logError('Error parsing graph YAML from file ${file.path}: $e', s);
        showStatusDialog(
          title: 'Error',
          message:
              'The selected file does not appear to be '
              'a valid Falcon graph. \nError: $e',
          type: StatusDialogType.error,
        );
      }
    } catch (e, s) {
      logError('Error loading file ${file.absolute.path}: $e', s);

      showStatusDialog(
        title: 'Error',
        message:
            'Failed to load graph from file: ${file.absolute.path} Error: $e',
        type: StatusDialogType.error,
      );
    }
  }

  Future<PriorityStatus> checkProcessPriority() async {
    try {
      final result = await Process.run('getcap', [_falconPath]);
      final newStatus = result.stdout.toString().contains('cap_sys_nice')
          ? PriorityStatus.prioritized
          : PriorityStatus.notPrioritized;
      if (_priorityStatus != PriorityStatus.prioritized &&
          newStatus == PriorityStatus.prioritized) {
        logInfo('Falcon process has been prioritized.');

        if (_falconProcess != null) {
          logInfo('Restarting falcon to apply new priority settings.');
          unawaited(killFalcon().then((_) => createFalconInstance()));
        } else {
          logInfo('Spawning falcon with prioritized settings.');
          unawaited(createFalconInstance());
        }
      }

      _priorityStatus = newStatus;
    } catch (e, s) {
      logError('Error checking priority: $e', s);
      _priorityStatus = PriorityStatus.unknown;
    }
    notifyListeners();
    return _priorityStatus;
  }

  Future<void> createFalconInstance() async {
    final pids = await _getExistingFalconPIDs();

    if (pids.isNotEmpty) {
      logInfo('Existing Falcon instances detected: $pids');
      if (kDebugMode) {
        unawaited(killOthersAndSpawnNew());
      } else {
        showOtherFalconInstancesBanner(pids: pids);
      }
      return;
    }

    if (_falconProcess != null) return;

    await _initializeZMQ();

    if (kDebugMode && _debugUseExistingFalconInstance) {
      notifyListeners();
      return;
    }

    try {
      // tmp solution, will fix on CPP side later
      if (kDebugMode) {
        final logDir = Directory('./build/falcon/logs');
        // ignore: avoid_slow_async_io
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }
      }

      _falconProcess = await Process.start(
        _falconPath,
        [
          '-c',
          if (kDebugMode) ...[
            'falcon/debug_config.yaml',
          ] else ...[
            '$ubuntuHomePath/.local/share/org.falcon-eyrie.falcon_gui/config.yaml',
          ],
        ],
      );
      _processExitCompleter = Completer<void>();
      _listenForExitCode();
      notifyListeners();
    } catch (e, s) {
      logError('Error creating falcon instance: $e', s);
    }
  }

  void _listenForExitCode() {
    unawaited(
      _falconProcess!.exitCode.then((_) {
        logInfo('Falcon process exitCode received');
        if (_processExitCompleter != null &&
            !_processExitCompleter!.isCompleted) {
          _processExitCompleter!.complete();
        }
      }),
    );
  }

  Future<List<int>> _getExistingFalconPIDs() async {
    final pgrepResult = await Process.run('pgrep', ['-f', _falconPath]);
    final pids = pgrepResult.stdout
        .toString()
        .trim()
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map(int.parse)
        .toList();
    return pids;
  }

  Future<void> killOthersAndSpawnNew() async {
    final pids = await _getExistingFalconPIDs();
    for (final pid in pids) {
      try {
        final result = Process.killPid(pid, ProcessSignal.sigkill);
        logInfo(
          'Killed existing Falcon process with PID: $pid '
          'Result: $result',
        );
      } catch (e, s) {
        logError('Error killing existing process $pid: $e', s);
      }
    }

    await createFalconInstance();
  }

  Future<void> _initializeZMQ() async {
    try {
      _falconZMQ = FalconZMQ();

      _falconZMQ!.addListener(notifyListeners);

      final connected = await _falconZMQ!.connect();
      if (!connected) {
        throw Exception('Failed to connect to Falcon via ZMQ');
      }

      logInfo('FalconManager: Connected to Falcon');
    } catch (e, s) {
      logError('Error initializing ZMQ: $e', s);
      rethrow;
    }
  }

  Future<void> killFalcon() async {
    logInfo('killFalcon called');
    try {
      showKillingFalconBanner();

      // Wait for process to terminate
      if (_falconProcess != null && _processExitCompleter != null) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await sendCommand(FalconZmqCommand.kill);
          // Wait for process to exit with 5 second timeout
          await Future.any([
            _processExitCompleter!.future,
            Future<void>.delayed(const Duration(seconds: 15)),
          ]);

          if (!_processExitCompleter!.isCompleted) {
            logInfo(
              'Process did not exit gracefully after 15 seconds, force killing',
            );
            _falconProcess!.kill(ProcessSignal.sigkill);
          } else {
            logInfo('Process exited successfully');
          }
        } catch (e, s) {
          logError('Error waiting for process to exit: $e', s);
        }
      }

      await _falconZMQ?.disconnect();
      await _falconZMQ?.dispose();
      _falconZMQ = null;

      _falconProcess = null;
      _processExitCompleter = null;

      notifyListeners();
    } catch (e, s) {
      logError('Error killing falcon instance: $e', s);
    }
  }

  /// Send a Falcon command
  Future<List<String>?> sendCommand(
    FalconZmqCommand command,
  ) async {
    if (_falconZMQ == null || !_falconZMQ!.isConnected) {
      logInfo('FalconManager: ZMQ not connected');
      return null;
    }
    return _falconZMQ!.sendCommand(command);
  }

  /// Send custom command parts
  Future<List<String>?> sendCommandParts(
    List<String> parts, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_falconZMQ == null || !_falconZMQ!.isConnected) {
      logInfo('FalconManager: ZMQ not connected');
      return null;
    }
    return _falconZMQ!.sendCommandParts(parts, timeout: timeout);
  }

  Future<void> onGraphChanged(FalconGraph graph) async {
    if (_currentGraphFile == null) {
      logError(
        'onGraphChanged called but no current '
        'graph file is set ${StackTrace.current}',
      );
      return;
    }

    if (falconState == FalconState.unknown) {
      // TODO(ben): dont create infinite Futures, instead, overwrite
      // the previous one, perhaps just use the debouncer
      Future.delayed(
        const Duration(milliseconds: 100),
        () => onGraphChanged(graph),
      );
      return;
    }

    if (falconState != FalconState.noGraph) {
      await sendCommand(FalconZmqCommand.graphDestroy);
    }
    final graphAsYaml = graph.toYaml();

    if (graphAsYaml.trim().isEmpty) {
      return;
    }

    await _currentGraphFile!.writeAsString(graphAsYaml);
    await _falconZMQ!.sendCommandParts(
      FalconZmqCommand.graphBuild(_currentGraphFile!.absolute.path),
    );
  }

  Future<void> onUIMetadataChanged(FalconGraph graph) async {
    if (_currentGraphFile == null) {
      logError(
        'onUIMetadataChanged called but no current '
        'graph file is set ${StackTrace.current}',
      );
      return;
    }
    _fileWriteDebounce(() async {
      await _currentGraphFile!.writeAsString(graph.toYaml());
    });
  }

  Future<void> toggleProcessingState() async {
    logInfo('toggleProcessingState called');
    if (falconState == FalconState.processing) {
      await sendCommand(FalconZmqCommand.graphStop);
    } else {
      await sendCommand(FalconZmqCommand.graphStart);
    }
  }
}

/// Falcon process priority status.
enum PriorityStatus {
  prioritized,
  notPrioritized,
  unknown,
}

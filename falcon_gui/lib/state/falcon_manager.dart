import 'dart:async';
import 'dart:io';

import 'package:falcon_gui/dialogs/status_dialog.dart';
import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/falcon_log.dart';
import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/model/falcon_zmq_command.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/state/falcon_zmq.dart';
import 'package:falcon_gui/utils/debounce.dart';
import 'package:falcon_gui/utils/file_picker.dart';
import 'package:falcon_gui/utils/local_config.dart';
import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/foundation.dart';

final FalconManager falconManager = FalconManager.instance;

class FalconManager extends ChangeNotifier {
  FalconManager._internal();

  static final FalconManager instance = FalconManager._internal();

  File? _currentGraphFile;
  File? get currentGraphFile => _currentGraphFile;
  String? get currentGraphFileName =>
      _currentGraphFile?.path.split(Platform.pathSeparator).last;

  final graphLoadedNotifier = ValueNotifier<FalconGraph?>(null);

  File get _defaultGraphFile =>
      File('$ubuntuHomePath/falcon/resources/graphs/new_graph.yaml')
        ..createSync(recursive: true);

  String get _falconPath {
    return '$ubuntuHomePath/.local/share/org.falcon-eyrie.falcon_gui/bin/falcon';
  }

  final _fileWriteDebounce = Debounce(delay: const Duration(milliseconds: 500));

  FalconZMQ? _falconZMQ;

  int? _localFalconBackendPid;
  int? get localFalconBackendPid => _localFalconBackendPid;
  Timer? _processExitWatchdogTimer;
  Completer<void>? _localBackendExitCompleter;

  // PriorityStatus _priorityStatus = PriorityStatus.unknown;

  // PriorityStatus get processPriority => _priorityStatus;

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

  Future<void> initialize() async {
    await _initializeZMQ();

    // Don't default to local,
    // let user choose remote vs local on startup
    await initLocalBackend();

    final lastGraphPath = localConfig.lastOpenedGraph;
    if (lastGraphPath != null) {
      final file = File(lastGraphPath);
      if (file.existsSync()) {
        unawaited(falconManager.loadFile(file: file));
      }
    } else {
      unawaited(loadFile(file: _defaultGraphFile));
    }
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

  // Future<PriorityStatus> checkProcessPriority() async {
  //   try {
  //     final result = await Process.run('getcap', [_falconPath]);
  //     final newStatus = result.stdout.toString().contains('cap_sys_nice')
  //         ? PriorityStatus.prioritized
  //         : PriorityStatus.notPrioritized;
  //     if (_priorityStatus != PriorityStatus.prioritized &&
  //         newStatus == PriorityStatus.prioritized) {
  //       logInfo('Falcon process has been prioritized.');

  //       if (_falconProcess != null) {
  //         logInfo('Restarting falcon to apply new priority settings.');
  //         unawaited(killFalcon().then((_) => createFalconInstance()));
  //       } else {
  //         logInfo('Spawning falcon with prioritized settings.');
  //         unawaited(createFalconInstance());
  //       }
  //     }

  //     _priorityStatus = newStatus;
  //   } catch (e, s) {
  //     logError('Error checking priority: $e', s);
  //     _priorityStatus = PriorityStatus.unknown;
  //   }
  //   notifyListeners();
  //   return _priorityStatus;
  // }

  Future<void> initLocalBackend() async {
    if (_localFalconBackendPid != null) return;

    try {
      final existingPid = await _getExistingFalconPID();

      if (existingPid != null) {
        logInfo(
          'Found existing local backend process with PID '
          '$existingPid, taking ownership.',
        );

        _localFalconBackendPid = existingPid;
      } else {
        final localBackendProcess = await Process.start(
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
        _localFalconBackendPid = localBackendProcess.pid;
        logInfo('Started new Falcon process with PID $_localFalconBackendPid');
      }

      _localBackendExitCompleter = Completer<void>();
      _startExitMonitoring();
      notifyListeners();
    } catch (e, s) {
      logError('Error creating falcon instance: $e', s);
    }
  }

  bool _isLocalBackendStillAlive() {
    return Directory('/proc/$_localFalconBackendPid').existsSync();
  }

  void _startExitMonitoring() {
    _processExitWatchdogTimer?.cancel();
    _processExitWatchdogTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (_localFalconBackendPid == null || !_isLocalBackendStillAlive()) {
          logInfo(
            'Falcon process (PID $_localFalconBackendPid) exit '
            'detected via polling',
          );

          timer.cancel();
          _localFalconBackendPid = null;

          if (_localBackendExitCompleter != null &&
              !_localBackendExitCompleter!.isCompleted) {
            _localBackendExitCompleter!.complete();
          }

          notifyListeners();
        }
      },
    );
  }

  /// Get existing Falcon PID on this machine using pgrep.
  /// If there are multiple instances (there shouldn't),
  /// first match is returned.
  Future<int?> _getExistingFalconPID() async {
    final pgrepResult = await Process.run('pgrep', ['-f', _falconPath]);
    final existingPids = pgrepResult.stdout
        .toString()
        .trim()
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map(int.parse)
        .toList();
    return existingPids.isNotEmpty ? existingPids.first : null;
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
      // Wait for process to terminate
      if (_localFalconBackendPid != null &&
          _localBackendExitCompleter != null) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          unawaited(sendCommand(FalconZmqCommand.kill));
          // Wait for process to exit with 2 second timeout
          await Future.any([
            _localBackendExitCompleter!.future,
            Future<void>.delayed(const Duration(seconds: 2)),
          ]);

          if (!_localBackendExitCompleter!.isCompleted) {
            logInfo(
              'Falcon backend did not exit gracefully with zmq command '
              'after 2 seconds, sending SIGKILL',
            );

            Process.killPid(_localFalconBackendPid!, ProcessSignal.sigkill);
          } else {
            logInfo('Falcon backend exited successfully');
          }
        } catch (e, s) {
          logError('Error waiting for process to exit: $e', s);
        }
      }

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

  @override
  Future<void> dispose() async {
    await _falconZMQ?.dispose();
    _processExitWatchdogTimer?.cancel();
    super.dispose();
  }
}

/// Falcon process priority status.
enum PriorityStatus {
  prioritized,
  notPrioritized,
  unknown,
}

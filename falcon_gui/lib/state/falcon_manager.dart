import 'dart:async';
import 'dart:io';

import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/falcon_log.dart';
import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/model/falcon_zmq_command.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/state/falcon_zmq.dart';
import 'package:falcon_gui/utils/debounce.dart';
import 'package:falcon_gui/utils/killing_falcon_banner.dart';
import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/other_falcon_instances_banner.dart';
import 'package:flutter/foundation.dart';

final FalconManager falconManager = FalconManager.instance;
const bool _debugUseExistingFalconInstance = true;

class FalconManager extends ChangeNotifier {
  FalconManager._internal();

  static final FalconManager instance = FalconManager._internal();

  String get _falconPath {
    final home = Platform.environment['HOME'] ?? '';
    return '/home/device/.local/share/org.falcon-eyrie.falcon_gui/bin/falcon'
        .replaceFirst(
          '~',
          home,
        );
  }

  Process? _falconProcess;
  FalconZMQ? _falconZMQ;
  Completer<void>? _processExitCompleter;

  PriorityStatus _priorityStatus = PriorityStatus.unknown;

  PriorityStatus get processPriority => _priorityStatus;

  String get processPriorityCommand =>
      'sudo setcap cap_sys_nice=eip $_falconPath';

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
          unawaited(killFalcon().then((_) => createFalcon()));
        } else {
          logInfo('Spawning falcon with prioritized settings.');
          unawaited(createFalcon());
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

  Future<void> createFalcon() async {
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
            '/home/device/.local/share/org.falcon-eyrie.falcon_gui/config.yaml',
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

    await createFalcon();
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
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sendCommand(FalconZmqCommand.kill);

      // Wait for process to terminate
      if (_falconProcess != null && _processExitCompleter != null) {
        try {
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

  List<FalconLog> get logs => _falconZMQ?.logs ?? [];

  bool get isLastLogAnError =>
      logs.isNotEmpty && logs.last.type == FalconLogType.error;
  FalconState get falconState => _falconZMQ?.falconState ?? FalconState.unknown;

  // TODO(ben):   dont use hardcoded path
  final _p = File('/home/device/falcon/resources/graphs/current.yaml');

  final _fileWriteDebounce = Debounce(delay: const Duration(milliseconds: 500));

  bool get canEditGraph {
    final state = falconState;
    return state != FalconState.processing &&
        state != FalconState.starting &&
        state != FalconState.stopping;
  }

  Future<void> onGraphChanged(FalconGraph graph) async {
    if (falconState == FalconState.unknown) {
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

    await _p.writeAsString(graphAsYaml);
    await _falconZMQ!.sendCommandParts(
      FalconZmqCommand.graphBuild(_p.path),
    );
  }

  Future<void> onUIMetadataChanged(FalconGraph graph) async {
    _fileWriteDebounce(() async {
      await _p.writeAsString(graph.toYaml());
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

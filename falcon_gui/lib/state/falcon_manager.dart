import 'dart:async';
import 'dart:io';

import 'package:falcon_gui/utils/zmq_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final FalconManager falconManager = FalconManager.instance;

class FalconManager extends ChangeNotifier {
  FalconManager._internal();

  static final FalconManager instance = FalconManager._internal();

  String get _falconPath {
    final home = Platform.environment['HOME'] ?? '';
    return '~/falcon/bin/falcon'.replaceFirst('~', home);
  }

  Process? _falconProcess;
  ZMQFFi? _zmq;
  ZMQContext? _zmqContext;
  ZMQSocket? _zmqSocket;

  PriorityStatus _priorityStatus = PriorityStatus.unknown;

  PriorityStatus get processPriority => _priorityStatus;

  String get processPriorityCommand =>
      'sudo setcap cap_sys_nice=eip $_falconPath';

  Future<void> createFalcon() async {
    if (_falconProcess != null) return;
    try {
      _falconProcess = await Process.start(_falconPath, []);
      await _initializeZMQ();
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating falcon instance: $e');
    }
  }

  Future<void> _initializeZMQ() async {
    try {
      _zmq = ZMQFFi();
      _zmqContext = _zmq!.ctxNew();
      _zmqSocket = _zmq!.socket(_zmqContext!, ZMQ_REQ);

      _zmq!.setSocketOption(_zmqSocket!, ZMQ_RCVTIMEO, 5000);

      final connectResult = _zmq!.connect(_zmqSocket!, 'tcp://localhost:5555');
      if (connectResult != 0) {
        throw Exception('Failed to connect to falcon: ${_zmq!.getErrno()}');
      }
      debugPrint('Connected to Falcon on port 5555');
    } catch (e) {
      debugPrint('Error initializing ZMQ: $e');
      rethrow;
    }
  }

  Future<void> killFalcon() async {
    debugPrint('killFalcon called');
    try {
      if (_zmqSocket != null) {
        _zmq!.close(_zmqSocket!);
      }
      if (_zmqContext != null) {
        _zmq!.ctxTerm(_zmqContext!);
      }
      _falconProcess?.kill();
      _falconProcess = null;
      _zmqSocket = null;
      _zmqContext = null;
      _zmq = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error killing falcon instance: $e');
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
        debugPrint('Falcon process has been prioritized.');

        if (_falconProcess != null) {
          debugPrint('Restarting falcon to apply new priority settings.');
          unawaited(killFalcon().then((_) => createFalcon()));
        } else {
          debugPrint('Spawning falcon with prioritized settings.');
          unawaited(createFalcon());
        }
      }

      _priorityStatus = newStatus;
    } catch (e) {
      debugPrint('Error checking priority: $e');
      _priorityStatus = PriorityStatus.unknown;
    }
    notifyListeners();
    return _priorityStatus;
  }

  Future<String?> sendCommand(
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_zmqSocket == null || _zmq == null) {
      debugPrint('ZMQ socket not initialized');
      return null;
    }
    try {
      final sendResult = _zmq!.send(_zmqSocket!, command.codeUnits);
      if (sendResult < 0) {
        debugPrint('Failed to send command: ${_zmq!.getErrno()}');
        return null;
      }

      final response = _zmq!.recv(_zmqSocket!);
      if (response == null || response.isEmpty) {
        debugPrint('Empty response received');
        return null;
      }

      return String.fromCharCodes(response);
    } catch (e) {
      debugPrint('Error sending command: $e');
      return null;
    }
  }

  Future<void> sendTestCommandSimple() async {
    final response = await sendCommand('kill');
    if (response != null) {
      debugPrint('Test command response: $response');
    } else {
      debugPrint('No response for test command');
    }
  }

  void debugConnectionStatus() {
    if (_zmqSocket == null) {
      debugPrint('Socket is null');
      return;
    }
    debugPrint('Socket is initialized');
    debugPrint('ZMQ error number: ${_zmq?.getErrno()}');
  }
}

/// Falcon process priority status.
enum PriorityStatus {
  prioritized,
  notPrioritized,
  unknown,
}

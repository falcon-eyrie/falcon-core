import 'dart:async';
import 'dart:io';

import 'package:dartzmq/dartzmq.dart';
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
  ZContext? _zmqContext;
  ZSyncSocket? _zmqSocket;
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
      _zmqContext = ZContext();
      // Create socket with REQ type
      final socket = _zmqContext!.createSocket(SocketType.req);
      socket.connect('tcp://127.0.0.1:5555');
      _zmqSocket = socket as ZSyncSocket;
      debugPrint('Connected to Falcon on port 5555');

      unawaited(_sendTestCommand());
    } catch (e) {
      debugPrint('Error initializing ZMQ: $e');
    }
  }

  Future<void> killFalcon() async {
    debugPrint('killFalcon called');
    if (_falconProcess == null) {
      debugPrint('No falcon process to kill');
      return;
    }
    try {
      debugPrint('Killing falcon process with PID: ${_falconProcess!.pid}');
      _zmqSocket?.close();
      unawaited(_zmqContext?.stop());
      _falconProcess?.kill();
      _falconProcess = null;
      _zmqSocket = null;
      _zmqContext = null;
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

  Future<String?> sendCommand(String command) async {
    if (_zmqSocket == null) {
      debugPrint('ZMQ socket not initialized');
      return null;
    }
    try {
      _zmqSocket!.sendString(command);
      final msg = await Future(() => _zmqSocket!.recv());
      if (msg.isEmpty) return null;
      final combined = <int>[];
      for (final frame in msg) {
        combined.addAll(frame.payload);
      }
      return String.fromCharCodes(combined);
    } catch (e) {
      debugPrint('Error sending command: $e');
      return null;
    }
  }

  Future<String?> sendCommandWithTimeout(
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_zmqSocket == null) {
      debugPrint('ZMQ socket not initialized');
      return null;
    }
    try {
      _zmqSocket!.sendString(command);
      final msg = await Future(() => _zmqSocket!.recv()).timeout(timeout);
      if (msg.isEmpty) return null;
      final combined = <int>[];
      for (final frame in msg) {
        combined.addAll(frame.payload);
      }
      return String.fromCharCodes(combined);
    } on TimeoutException {
      debugPrint('Command timeout: $command');
      return null;
    } catch (e) {
      debugPrint('Error sending command: $e');
      return null;
    }
  }

  Future<void> _sendTestCommand() async {
    debugPrint('Sending test command to Falcon');
    final response = await sendCommand('ping');
    debugPrint('Received response: $response');
  }
}

/// Falcon process priority status.
enum PriorityStatus {
  prioritized,
  notPrioritized,
  unknown,
}

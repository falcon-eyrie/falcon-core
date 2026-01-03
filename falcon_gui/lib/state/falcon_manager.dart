import 'dart:async';
import 'dart:io';

import 'package:dartzmq/dartzmq.dart';
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
  ZContext? _zmqContext;
  ZSocket? _zmqSocket;
  late StreamController<ZMessage> _messageController;

  PriorityStatus _priorityStatus = PriorityStatus.unknown;

  PriorityStatus get processPriority => _priorityStatus;

  String get processPriorityCommand =>
      'sudo setcap cap_sys_nice=eip $_falconPath';

  Future<void> createFalcon() async {
    if (_falconProcess != null) return;
    try {
      await _initializeZMQ();
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating falcon instance: $e');
    }
  }

  Future<void> _initializeZMQ() async {
    try {
      _zmqContext = ZContext();
      _zmqSocket = _zmqContext!.createSocket(SocketType.req);

      // Create a broadcast stream from the socket's messages
      _messageController = StreamController<ZMessage>.broadcast();
      _zmqSocket!.messages.listen((message) {
        _messageController.add(message);
      });

      _zmqSocket!.connect('tcp://localhost:5555');
      debugPrint('Connected to Falcon on port 5555');
    } catch (e) {
      debugPrint('Error initializing ZMQ: $e');
    }
  }

  Future<void> killFalcon() async {
    debugPrint('killFalcon called');
    try {
      await _messageController.close();
      _zmqSocket?.close();
      await _zmqContext?.stop();
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

  Future<String?> sendCommand(
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_zmqSocket == null) {
      debugPrint('ZMQ socket not initialized');
      return null;
    }
    try {
      _zmqSocket!.sendString(command);
      final message = await _messageController.stream.first.timeout(timeout);
      return _parseMessage(message);
    } on TimeoutException {
      debugPrint('Command timeout: $command');
      return null;
    } catch (e) {
      debugPrint('Error sending command: $e');
      return null;
    }
  }

  Future<void> sendTestCommandSimple() async {
    debugPrint('Sending test command to Falcon');
    try {
      _zmqSocket!.sendString('info');
      debugPrint('Sent "info" command');

      final message = await _messageController.stream.first.timeout(
        const Duration(seconds: 5),
      );

      if (message.isEmpty) {
        debugPrint('Empty response received');
        return;
      }

      final result = _parseMessage(message);
      debugPrint('Response: $result');
    } on TimeoutException {
      debugPrint('Test command timeout');
    } catch (e) {
      debugPrint('Error in test command: $e');
    }
  }

  String? _parseMessage(ZMessage message) {
    if (message.isEmpty) return null;
    final combined = <int>[];
    final frameList = message.toList();
    for (int i = 0; i < frameList.length; i++) {
      combined.addAll(frameList[i].payload);
      if (i < frameList.length - 1) {
        combined.add(32); // space
      }
    }
    return String.fromCharCodes(combined);
  }
}

/// Falcon process priority status.
enum PriorityStatus {
  prioritized,
  notPrioritized,
  unknown,
}

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:falcon_gui/model/falcon_log.dart';
import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/model/falcon_zmq_command.dart';
import 'package:falcon_gui/utils/zmq/zmq_constants.dart';
import 'package:falcon_gui/utils/zmq/zmq_isolate_worker.dart';
import 'package:flutter/foundation.dart';

/// ZMQ connection wrapper for Falcon
class FalconZMQ extends ChangeNotifier {
  FalconZMQ({
    this.address = 'tcp://localhost',
    this.commandPort = 5555,
    this.logPort = 5556,
  });

  final String address;
  final int commandPort;
  final int logPort;

  ZMQIsolateWorker? _zmqWorker;
  StreamSubscription<List<String>>? _logSubscription;
  Completer<void>? _socketsReadyCompleter;

  bool get isConnected => _socketsReadyCompleter?.isCompleted ?? false;

  final _logs = <FalconLog>[];

  List<FalconLog> get logs => List.unmodifiable(_logs);

  bool _isWaitingForStateResponse = false;

  FalconState? _stateFromResponse;

  FalconState get falconState {
    final lastState = _logs.lastWhereOrNull(
      (log) => log.type == FalconLogType.state,
    );

    // If no state log found, try to get state via command
    if (lastState == null) {
      if (_stateFromResponse != null) {
        return _stateFromResponse!;
      }

      if (!_isWaitingForStateResponse) {
        _isWaitingForStateResponse = true;

        unawaited(_getStateViaCommand());
      }
      return FalconState.unknown;
    }

    return FalconState.fromString(lastState.message);
  }

  Future<void> _getStateViaCommand() async {
    try {
      await _socketsReadyCompleter?.future;

      final zmqStateResponseParts = await sendCommand(
        FalconZmqCommand.graphState,
      );

      _stateFromResponse = FalconState.fromString(zmqStateResponseParts!.first);
    } catch (e) {
      debugPrint('FalconZMQ: Failed to get state via command: $e');
    } finally {
      _isWaitingForStateResponse = false;
      notifyListeners();
    }
  }

  static const _commandSocketName = 'command';
  static const _logSocketName = 'log';

  /// Initialize ZMQ and connect all sockets
  Future<bool> connect() async {
    if (isConnected) return true;

    try {
      _socketsReadyCompleter = Completer<void>();
      _zmqWorker = ZMQIsolateWorker();
      await _zmqWorker!.start();

      // Setup command socket (REQ)
      await _zmqWorker!.createSocket(
        socketId: _commandSocketName,
        endpoint: '$address:$commandPort',
        socketType: ZMQ_REQ,
        receiveTimeout: 5000,
      );

      // Setup log socket (SUB)
      await _zmqWorker!.createSocket(
        socketId: _logSocketName,
        endpoint: '$address:$logPort',
        socketType: ZMQ_SUB,
        receiveTimeout: 1000,
        subscribeAll: true,
      );

      debugPrint(
        'FalconZMQ: Connected to $address:$commandPort and $address:$logPort',
      );
      _socketsReadyCompleter!.complete();

      unawaited(startLogListener());

      return true;
    } catch (e) {
      debugPrint('FalconZMQ: Connection to $address failed: $e');
      _socketsReadyCompleter?.completeError(e);
      await disconnect();
      return false;
    }
  }

  /// Send a Falcon command and wait for response
  Future<List<String>?> sendCommand(
    FalconZmqCommand command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return _sendCommandParts(command.serialize(), timeout: timeout);
  }

  /// Send custom Falcon command parts
  Future<List<String>?> sendCommandParts(
    List<String> parts, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return _sendCommandParts(parts, timeout: timeout);
  }

  Future<List<String>?> _sendCommandParts(
    List<String> parts, {
    required Duration timeout,
  }) async {
    if (_zmqWorker == null || !isConnected) {
      return null;
    }

    try {
      final response = await _zmqWorker!.sendAndReceive(
        _commandSocketName,
        parts,
      );
      return response;
    } catch (e) {
      debugPrint('FalconZMQ: Command failed: $e');
      return null;
    }
  }

  /// Start listening for log messages using long-lived isolate
  Future<void> startLogListener() async {
    if (_zmqWorker == null || !isConnected) {
      return;
    }

    try {
      _logSubscription = _zmqWorker!
          .receiveStream(_logSocketName)
          .listen(
            (logMessage) {
              if (logMessage.isNotEmpty) {
                _logs.add(FalconLog.fromZmqParts(logMessage));
                notifyListeners();
              }
            },
            onError: (dynamic e) {
              debugPrint('FalconZMQ: Log listener error: $e');
            },
          );
    } catch (e) {
      debugPrint('FalconZMQ: Failed to start log listener: $e');
    }
  }

  /// Disconnect all sockets and cleanup
  Future<void> disconnect() async {
    _socketsReadyCompleter = null;

    await _logSubscription?.cancel();
    _logSubscription = null;

    await _zmqWorker?.stop();
    _zmqWorker = null;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await disconnect();
  }
}

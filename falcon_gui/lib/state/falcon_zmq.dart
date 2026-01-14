import 'dart:async';

import 'package:collection/collection.dart';
import 'package:falcon_gui/model/falcon_log.dart';
import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/model/falcon_zmq_command.dart';
import 'package:falcon_gui/utils/zmq/zmq_constants.dart';
import 'package:falcon_gui/utils/zmq/zmq_ffi.dart';
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

  ZMQFFi? _zmq;
  ZMQContext? _context;
  ZMQSocket? _commandSocket;
  ZMQSocket? _logSocket;
  ZMQIsolateWorker? _zmqIsolateWorker;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _logs = <FalconLog>[];

  List<FalconLog> get logs => List.unmodifiable(_logs);

  bool _isWaitingForStateResponse = false;

  FalconState? _stateFromResponse;

  FalconState get falconState {
    final lastState = _logs.lastWhereOrNull(
      (log) => log.type == FalconLogType.state,
    );

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
      final zmqStateResponseParts = await sendCommand(
        FalconZmqCommand.graphState,
      );

      _stateFromResponse = FalconState.fromString(
        zmqStateResponseParts!.first,
      );
    } catch (e) {
      _stateFromResponse = FalconState.unknown;
    } finally {
      _isWaitingForStateResponse = false;
      notifyListeners();
    }
  }

  /// Initialize ZMQ and connect all sockets
  Future<bool> connect() async {
    if (_isConnected) return true;

    try {
      _zmq = ZMQFFi();
      _context = _zmq!.ctxNew();

      // Connect command socket (REQ)
      _commandSocket = _zmq!.socket(_context!, ZMQ_REQ);
      _zmq!.setSocketOption(_commandSocket!, ZMQ_RCVTIMEO, 5000);
      final cmdResult = _zmq!.connect(_commandSocket!, '$address:$commandPort');
      if (cmdResult != 0) {
        throw Exception('Failed to connect command socket');
      }

      debugPrint('FalconZMQ: Connected to $address:$commandPort');
      _isConnected = true;

      try {
        _logSocket = _zmq!.socket(_context!, ZMQ_SUB);
        _zmq!.setSocketOption(_logSocket!, ZMQ_RCVTIMEO, 1000);
        final logResult = _zmq!.connect(_logSocket!, '$address:$logPort');
        if (logResult != 0) {
          throw Exception('Failed to connect log socket');
        }
        // Subscribe to all messages (empty topic filter)
        _zmq!.subscribeAll(_logSocket!);
        debugPrint('FalconZMQ: Connected log socket to $address:$logPort');

        // Start long-lived isolate receiver for logs
        _zmqIsolateWorker = ZMQIsolateWorker(_logSocket!.address);
        await _zmqIsolateWorker!.start();
        unawaited(startLogListener());
      } catch (e) {
        debugPrint(
          'FalconZMQ: Failed to connect log socket at $address:$logPort: $e',
        );
      }

      return true;
    } catch (e) {
      debugPrint('FalconZMQ: Connection to $address:$commandPort failed: $e');
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
    if (_commandSocket == null || _zmq == null || !_isConnected) {
      return null;
    }

    try {
      // Use ZMQ FFI to send/receive multipart strings
      _zmq!.sendMultipartStrings(_commandSocket!, parts);
      final responseStr = await _zmq!.recvMultipartStrings(
        _commandSocket!,
      );

      return responseStr;
    } catch (e) {
      debugPrint('FalconZMQ: Command failed: $e');
      return null;
    }
  }

  /// Start listening for log messages using long-lived isolate
  Future<void> startLogListener() async {
    if (_zmqIsolateWorker == null || !_isConnected) {
      return;
    }

    try {
      while (_isConnected && _zmqIsolateWorker != null) {
        try {
          final logMessage = await _zmqIsolateWorker!.recvMultipartStrings();
          if (logMessage.isNotEmpty) {
            _logs.add(FalconLog.fromZmqParts(logMessage));
            notifyListeners();
          }
        } catch (e) {
          // Timeout or error, continue loop if still connected
          if (!_isConnected) break;
        }
      }
    } catch (e) {
      debugPrint('FalconZMQ: Log listener error: $e');
    }
  }

  /// Disconnect all sockets and cleanup
  Future<void> disconnect() async {
    _isConnected = false;

    // Stop long-lived isolate
    await _zmqIsolateWorker?.stop();
    _zmqIsolateWorker = null;

    if (_commandSocket != null) {
      _zmq?.close(_commandSocket!);
      _commandSocket = null;
    }
    if (_logSocket != null) {
      _zmq?.close(_logSocket!);
      _logSocket = null;
    }
    if (_context != null) {
      _zmq?.ctxTerm(_context!);
      _context = null;
    }
    _zmq = null;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await disconnect();
  }
}

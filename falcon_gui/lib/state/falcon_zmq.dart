import 'dart:async';
import 'dart:convert';
import 'package:falcon_gui/utils/zmq_ffi.dart';
import 'package:flutter/foundation.dart';

/// Falcon commands matching Python FalconCommand enum
enum FalconCommand {
  graphStart,
  graphStop,
  graphTest,
  graphDestroy,
  graphState,
  graphYaml,
  info,
  documentation,
  quit,
  kill,
  testOn,
  testOff,
  testToggle,
  resourcesList
  ;

  /// Convert command to list of string parts for ZMQ multipart message
  List<String> serialize() {
    switch (this) {
      case FalconCommand.graphStart:
        return ['graph', 'start'];
      case FalconCommand.graphStop:
        return ['graph', 'stop'];
      case FalconCommand.graphTest:
        return ['graph', 'test'];
      case FalconCommand.graphDestroy:
        return ['graph', 'destroy'];
      case FalconCommand.graphState:
        return ['graph', 'state'];
      case FalconCommand.graphYaml:
        return ['graph', 'yaml'];
      case FalconCommand.info:
        return ['info'];
      case FalconCommand.documentation:
        return ['documentation'];
      case FalconCommand.quit:
        return ['quit'];
      case FalconCommand.kill:
        return ['kill'];
      case FalconCommand.testOn:
        return ['test', 'true'];
      case FalconCommand.testOff:
        return ['test', 'false'];
      case FalconCommand.testToggle:
        return ['test'];
      case FalconCommand.resourcesList:
        return ['resources', 'list'];
    }
  }

  /// Create custom command with arbitrary parts
  static List<String> custom(List<String> parts) => parts;

  /// Create graph build command
  static List<String> graphBuild(String graphFile) => [
    'graph',
    'build',
    graphFile,
  ];

  /// Create resources list type command
  static List<String> resourcesListType(String resourceType) => [
    'resources',
    'list',
    resourceType,
  ];

  /// Create resources graph command
  static List<String> resourcesGraph(String graphPath) => [
    'resources',
    'graphs',
    graphPath,
  ];
}

/// ZMQ connection wrapper for Falcon
class FalconZMQ {
  FalconZMQ({
    this.address = 'tcp://localhost',
    this.commandPort = 5555,
    this.logPort = 5556,
    this.dataPort = 7777,
  });

  final String address;
  final int commandPort;
  final int logPort;
  final int dataPort;

  ZMQFFi? _zmq;
  ZMQContext? _context;
  ZMQSocket? _commandSocket;
  ZMQSocket? _logSocket;
  ZMQSocket? _dataSocket;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Stream controllers for different data types
  final _logStreamController = StreamController<String>.broadcast();
  final _commandResponseController = StreamController<String>.broadcast();
  final _dataStreamController = StreamController<List<int>>.broadcast();

  Stream<String> get logStream => _logStreamController.stream;
  Stream<String> get commandResponseStream => _commandResponseController.stream;
  Stream<List<int>> get dataStream => _dataStreamController.stream;

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
      return true;
    } catch (e) {
      debugPrint('FalconZMQ: Connection failed: $e');
      await disconnect();
      return false;
    }
  }

  /// Send a command and wait for response
  Future<String?> sendCommand(
    FalconCommand command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return _sendCommandParts(command.serialize(), timeout: timeout);
  }

  /// Send custom command parts
  Future<String?> sendCommandParts(
    List<String> parts, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return _sendCommandParts(parts, timeout: timeout);
  }

  Future<String?> _sendCommandParts(
    List<String> parts, {
    required Duration timeout,
  }) async {
    if (_commandSocket == null || _zmq == null || !_isConnected) {
      return null;
    }

    try {
      final commandStr = parts.join(' ');

      // Send multipart message (simulate by sending joined parts)
      // In a full implementation, you'd send each part separately
      final sendResult = _zmq!.send(_commandSocket!, utf8.encode(commandStr));
      if (sendResult < 0) {
        return null;
      }

      // Receive response
      final response = _zmq!.recv(_commandSocket!);
      if (response == null || response.isEmpty) {
        return null;
      }

      final responseStr = utf8.decode(response);
      _commandResponseController.add(responseStr);
      return responseStr;
    } catch (e) {
      return null;
    }
  }

  /// Start listening for log messages in a separate isolate
  /// (For now, this is a placeholder - full isolate implementation
  /// would require moving this to a top-level function)
  Future<void> startLogListener() async {}

  /// Start listening for data messages in a separate isolate
  Future<void> startDataListener() async {}

  /// Disconnect all sockets and cleanup
  Future<void> disconnect() async {
    _isConnected = false;

    if (_commandSocket != null) {
      _zmq?.close(_commandSocket!);
      _commandSocket = null;
    }
    if (_logSocket != null) {
      _zmq?.close(_logSocket!);
      _logSocket = null;
    }
    if (_dataSocket != null) {
      _zmq?.close(_dataSocket!);
      _dataSocket = null;
    }
    if (_context != null) {
      _zmq?.ctxTerm(_context!);
      _context = null;
    }
    _zmq = null;
  }

  /// Dispose and close streams
  Future<void> dispose() async {
    unawaited(_logStreamController.close());
    unawaited(_commandResponseController.close());
    unawaited(_dataStreamController.close());
  }
}

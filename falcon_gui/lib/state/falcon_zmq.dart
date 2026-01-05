import 'dart:async';
import 'package:falcon_gui/utils/zmq_ffi.dart';
import 'package:flutter/foundation.dart';

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
  final _commandResponseController = StreamController<List<String>>.broadcast();
  final _dataStreamController = StreamController<List<int>>.broadcast();

  Stream<String> get logStream => _logStreamController.stream;
  Stream<List<String>> get commandResponseStream =>
      _commandResponseController.stream;
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
      final responseStr = _zmq!.recvMultipartStrings(_commandSocket!);

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

/// Falcon commands matching Python FalconCommand enum
enum FalconZmqCommand {
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
      case FalconZmqCommand.graphStart:
        return ['graph', 'start'];
      case FalconZmqCommand.graphStop:
        return ['graph', 'stop'];
      case FalconZmqCommand.graphTest:
        return ['graph', 'test'];
      case FalconZmqCommand.graphDestroy:
        return ['graph', 'destroy'];
      case FalconZmqCommand.graphState:
        return ['graph', 'state'];
      case FalconZmqCommand.graphYaml:
        return ['graph', 'yaml'];
      case FalconZmqCommand.info:
        return ['info'];
      case FalconZmqCommand.documentation:
        return ['documentation'];
      case FalconZmqCommand.quit:
        return ['quit'];
      case FalconZmqCommand.kill:
        return ['kill'];
      case FalconZmqCommand.testOn:
        return ['test', 'true'];
      case FalconZmqCommand.testOff:
        return ['test', 'false'];
      case FalconZmqCommand.testToggle:
        return ['test'];
      case FalconZmqCommand.resourcesList:
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

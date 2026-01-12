import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:falcon_gui/utils/zmq/zmq_ffi.dart';

/// Long-lived isolate for continuous ZMQ message reception.
/// Reuses the same isolate for multiple receive operations.
class ZMQIsolateReceiver {
  ZMQIsolateReceiver(this.socketAddress);

  final int socketAddress;
  Isolate? _isolate;
  SendPort? _commandPort;
  ReceivePort? _responsePort;
  final _responseController = StreamController<_IsolateResponse>.broadcast();
  int _requestId = 0;

  /// Start the long-lived isolate
  Future<void> start() async {
    if (_isolate != null) return;

    _responsePort = ReceivePort();
    _responsePort!.listen((message) {
      if (message is SendPort) {
        _commandPort = message;
      } else if (message is _IsolateResponse) {
        _responseController.add(message);
      }
    });

    _isolate = await Isolate.spawn(
      _continuousReceiveIsolate,
      _IsolateInit(
        socketAddress: socketAddress,
        sendPort: _responsePort!.sendPort,
      ),
    );

    // Wait for isolate to send back its command port
    await _responseController.stream.firstWhere(
      (response) => response.requestId == -1,
    );
  }

  /// Receive a multipart message
  Future<List<List<int>>> recvMultipart() async {
    if (_commandPort == null) {
      throw Exception('Isolate not started');
    }

    final requestId = _requestId++;
    final completer = Completer<List<List<int>>>();

    // Listen for this specific response
    late StreamSubscription<_IsolateResponse> subscription;
    subscription = _responseController.stream.listen((response) {
      if (response.requestId == requestId) {
        unawaited(subscription.cancel());
        if (response.error != null) {
          completer.completeError(response.error!);
        } else {
          completer.complete(response.data as List<List<int>>);
        }
      }
    });

    // Send request
    _commandPort!.send(_IsolateRequest(requestId: requestId));

    return completer.future;
  }

  /// Receive and decode multipart message as strings
  Future<List<String>> recvMultipartStrings() async {
    final parts = await recvMultipart();
    return parts.map((bytes) {
      try {
        return utf8.decode(bytes, allowMalformed: false);
      } catch (e) {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }).toList();
  }

  /// Stop the isolate
  Future<void> stop() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commandPort = null;
    _responsePort?.close();
    _responsePort = null;
    await _responseController.close();
  }

  /// Isolate entry point for continuous receiving
  static void _continuousReceiveIsolate(_IsolateInit init) {
    final commandPort = ReceivePort();
    final zmq = ZMQFFi();
    final sock = Pointer<Void>.fromAddress(init.socketAddress);

    // Send command port back to main isolate
    init.sendPort.send(commandPort.sendPort);
    init.sendPort.send(_IsolateResponse(requestId: -1, data: null));

    // Listen for receive requests
    commandPort.listen((message) {
      if (message is _IsolateRequest) {
        try {
          final result = zmq.recvMultipartSync(sock);
          init.sendPort.send(
            _IsolateResponse(
              requestId: message.requestId,
              data: result,
            ),
          );
        } catch (e) {
          init.sendPort.send(
            _IsolateResponse(
              requestId: message.requestId,
              data: null,
              error: e.toString(),
            ),
          );
        }
      }
    });
  }
}

/// Initialization parameters for long-lived isolate
class _IsolateInit {
  _IsolateInit({
    required this.socketAddress,
    required this.sendPort,
  });

  final int socketAddress;
  final SendPort sendPort;
}

/// Request to isolate
class _IsolateRequest {
  _IsolateRequest({required this.requestId});
  final int requestId;
}

/// Response from isolate
class _IsolateResponse {
  _IsolateResponse({
    required this.requestId,
    required this.data,
    this.error,
  });

  final int requestId;
  final dynamic data;
  final String? error;
}

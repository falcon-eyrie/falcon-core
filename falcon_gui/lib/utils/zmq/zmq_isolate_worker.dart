import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/zmq/zmq_constants.dart';
import 'package:falcon_gui/utils/zmq/zmq_ffi.dart';

/// Generic ZMQ isolate worker
class ZMQIsolateWorker {
  Isolate? _isolate;
  late SendPort _sendPort;
  final _receivePort = ReceivePort();
  final _responseCompleters = <int, Completer<dynamic>>{};
  final _streamControllers = <int, StreamController<List<String>>>{};
  int _nextRequestId = 0;

  Future<void> start() async {
    _isolate = await Isolate.spawn(
      _broker,
      _WorkerInitData(
        loggerSendPort,
        _receivePort.sendPort,
      ),
      onError: loggerSendPort,
    );

    final completer = Completer<SendPort>();
    _receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else if (message is Map) {
        final requestId = message['id'] as int;

        if (message['stream'] == true) {
          final controller = _streamControllers[requestId];
          if (message.containsKey('error')) {
            controller?.addError(message['error'] as Object);
            unawaited(controller?.close());
            _streamControllers.remove(requestId);
          } else if (message['done'] == true) {
            unawaited(controller?.close());
            _streamControllers.remove(requestId);
          } else {
            controller?.add(message['result'] as List<String>);
          }
        } else {
          final completer = _responseCompleters.remove(requestId);
          if (message.containsKey('error')) {
            completer?.completeError(message['error'] as String);
          } else {
            completer?.complete(message['result']);
          }
        }
      }
    });

    _sendPort = await completer.future;
  }

  Future<void> createSocket({
    required String socketId,
    required String endpoint,
    required int socketType,
    int? receiveTimeout,
    bool subscribeAll = false,
  }) {
    return _send({
      'op': 'create',
      'socketId': socketId,
      'endpoint': endpoint,
      'socketType': socketType,
      'receiveTimeout': receiveTimeout,
      'subscribeAll': subscribeAll,
    });
  }

  Future<List<String>> sendAndReceive(String socketId, List<String> parts) {
    return _send({
      'op': 'sendRecv',
      'socketId': socketId,
      'parts': parts,
    });
  }

  Stream<List<String>> receiveStream(String socketId) {
    final id = _nextRequestId++;
    final controller = StreamController<List<String>>();
    _streamControllers[id] = controller;
    _sendPort.send({'id': id, 'op': 'recvStream', 'socketId': socketId});
    return controller.stream;
  }

  Future<T> _send<T>(Map<String, dynamic> data) {
    final id = _nextRequestId++;
    final completer = Completer<T>();
    _responseCompleters[id] = completer;
    _sendPort.send({'id': id, ...data});
    return completer.future;
  }

  Future<void> stop() async {
    _sendPort.send({'op': 'stop'});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort.close();
  }

  static void _broker(_WorkerInitData workerInitData) {
    attachLogger(workerInitData.loggerPort);
    final mainSendPort = workerInitData.mainPort;

    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    ZMQFFi? zmq;
    ZMQContext? context;
    final sockets = <String, ZMQSocket>{};
    final socketConfigs = <String, _SocketConfig>{};
    final streamIsolates = <int, Isolate>{};

    receivePort.listen((message) async {
      logInfo('Received: $message');
      if (message is! Map) return;

      final id = message['id'] as int?;
      final op = message['op'] as String;

      try {
        switch (op) {
          case 'create':
            zmq ??= ZMQFFi();
            context ??= zmq!.ctxNew();

            logInfo('libzmq version: ${zmq!.version()}');
            final zmqSocketType = message['socketType'] as int;
            final socket = zmq!.socket(context!, zmqSocketType);

            if (message['receiveTimeout'] != null) {
              zmq!.setSocketOption(
                socket,
                ZMQ_RCVTIMEO,
                message['receiveTimeout'] as int,
              );
            }

            final socketType = message['socketType'] as int;
            if (socketType == ZMQ_REQ) {
              zmq!.setSocketOption(socket, ZMQ_REQ_RELAXED, 1);
              zmq!.setSocketOption(socket, ZMQ_REQ_CORRELATE, 1);
            }

            zmq!.connect(socket, message['endpoint'] as String);

            if (message['subscribeAll'] == true &&
                message['socketType'] == ZMQ_SUB) {
              zmq!.subscribeAll(socket);
            }

            final socketId = message['socketId'] as String;
            sockets[socketId] = socket;
            socketConfigs[socketId] = _SocketConfig(
              endpoint: message['endpoint'] as String,
              socketType: message['socketType'] as int,
              receiveTimeout: message['receiveTimeout'] as int?,
              subscribeAll: message['subscribeAll'] as bool? ?? false,
            );
            mainSendPort.send({'id': id, 'result': null});

          case 'sendRecv':
            final socket = sockets[message['socketId']];
            if (socket == null) throw Exception('Socket not found');

            zmq!.sendMultipartStrings(socket, message['parts'] as List<String>);
            final result = zmq!.recvMultipartStringsSync(socket);
            mainSendPort.send({'id': id, 'result': result});

          case 'recvStream':
            final socketId = message['socketId'] as String;
            final config = socketConfigs[socketId];
            if (config == null) throw Exception('Socket config not found');

            // Spawn separate isolate for streaming
            streamIsolates[id!] = await Isolate.spawn(
              _subscriber,
              _StreamIsolateData(
                mainSendPort,
                workerInitData.loggerPort,
                id,
                config,
              ),
            );

          case 'stop':
            for (final isolate in streamIsolates.values) {
              isolate.kill(priority: Isolate.immediate);
            }
            streamIsolates.clear();
            receivePort.close();
        }
      } catch (e, s) {
        logError('ZMQIsolateWorker _brokerWorker error: $e', s);
        mainSendPort.send({'id': id, 'error': e.toString()});
      }
    });
  }

  static void _subscriber(_StreamIsolateData data) {
    attachLogger(data.loggerPort);

    final zmq = ZMQFFi();
    final context = zmq.ctxNew();
    final socket = zmq.socket(context, data.config.socketType);

    if (data.config.receiveTimeout != null) {
      zmq.setSocketOption(socket, ZMQ_RCVTIMEO, data.config.receiveTimeout!);
    }

    zmq.connect(socket, data.config.endpoint);

    if (data.config.subscribeAll && data.config.socketType == ZMQ_SUB) {
      if (zmq.subscribeAll(socket)) {
        logInfo('Subscribed to all topics on ${data.config.endpoint}');
      }
    }

    while (true) {
      sleep(const Duration(milliseconds: 100));

      try {
        final result = zmq.recvMultipartStringsSync(socket);
        data.sendPort.send({
          'id': data.id,
          'stream': true,
          'result': result,
        });
      } catch (e, s) {
        logError('ZMQIsolateWorker _subscriptionLoop error: $e', s);
        if (!e.toString().contains('Resource temporarily unavailable')) {
          data.sendPort.send({
            'id': data.id,
            'stream': true,
            'error': e.toString(),
          });
        }
      }
    }
  }
}

class _SocketConfig {
  const _SocketConfig({
    required this.endpoint,
    required this.socketType,
    this.receiveTimeout,
    this.subscribeAll = false,
  });

  final String endpoint;
  final int socketType;
  final int? receiveTimeout;
  final bool subscribeAll;
}

class _WorkerInitData {
  _WorkerInitData(this.loggerPort, this.mainPort);
  final SendPort loggerPort;
  final SendPort mainPort;
}

class _StreamIsolateData {
  _StreamIsolateData(this.sendPort, this.loggerPort, this.id, this.config);

  final SendPort sendPort;
  final SendPort loggerPort;
  final int id;
  final _SocketConfig config;
}

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:falcon_gui/live_view/models/live_view_isolate_config.dart';
import 'package:falcon_gui/live_view/plot_drawer.dart';
import 'package:falcon_gui/live_view/signal_parser.dart';
import 'package:flutter/services.dart';

Future<void> liveViewIsolate(LiveViewInitConfig config) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(config.token);
  await LiveViewWorker(config).start();
}

class LiveViewWorker {
  LiveViewWorker(this.config);

  final LiveViewInitConfig config;
  final ReceivePort _commandPort = ReceivePort();

  WebSocket? _activeConnection;
  Timer? _reconnectTimer;

  Map<String, LiveViewRenderParams> _renderParams = {};
  int _visibleSamples = 90000;

  var _isFrozen = false;

  Future<void> start() async {
    config.controllerSendPort.send(_commandPort.sendPort);
    _commandPort.listen(_handleUiCommand);
    await _establishWSConnection();
  }

  void _handleUiCommand(dynamic message) {
    if (message is Map<String, LiveViewRenderParams>) {
      _renderParams = message;
      if (!_isFrozen) {
        _generateRenderPayload();
      }
    } else if (message is int) {
      _visibleSamples = message;
      if (!_isFrozen) {
        _generateRenderPayload();
      }
    } else if (message is bool) {
      _isFrozen = message;
      if (!_isFrozen) {
        _generateRenderPayload();
      }
    }
  }

  void _generateRenderPayload() {
    PlotDrawer.generateRenderPayload(
      sendPort: config.controllerSendPort,
      renderParams: _renderParams,
      visibleSamples: _visibleSamples,
    );
  }

  Future<void> _establishWSConnection() async {
    if (_reconnectTimer != null) return;
    try {
      final ws = await WebSocket.connect(
        config.wsAddress,
      ).timeout(const Duration(seconds: 5));
      ws.pingInterval = const Duration(seconds: 5);
      _activeConnection = ws;
      config.controllerSendPort.send('CONNECTED');

      ws.listen(
        (dynamic raw) {
          try {
            SignalParser.parseRawPacket(raw as Uint8List);
            if (!_isFrozen) {
              _generateRenderPayload();
            }
          } catch (_) {}
        },
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    unawaited(_activeConnection?.close());
    _activeConnection = null;
    config.controllerSendPort.send('CLEAR_BUFFERS');
    _reconnectTimer = Timer(const Duration(seconds: 1), () {
      _reconnectTimer = null;
      unawaited(_establishWSConnection());
    });
  }
}

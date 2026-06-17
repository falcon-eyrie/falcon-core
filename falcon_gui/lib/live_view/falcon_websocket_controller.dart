import 'dart:async';
import 'dart:io';

import 'package:falcon_gui/live_view/falcon_ws_message.dart';
import 'package:falcon_gui/live_view/live_view_controller.dart';
import 'package:falcon_gui/utils/logger.dart';
import 'package:flutter/foundation.dart';

final falconWSController = FalconWSController();

class FalconWSController extends ChangeNotifier {
  FalconWSController() {
    unawaited(_establishWSConnection());
  }
  final String _address = 'ws://0.0.0.0:5550';

  bool _isConnected = false;
  WebSocket? _activeConnection;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get address => _address;

  Future<void> _establishWSConnection() async {
    if (_isConnecting || _activeConnection != null) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isConnecting = true;
    notifyListeners();

    try {
      final ws = await WebSocket.connect(
        _address,
      ).timeout(const Duration(seconds: 5));
      logInfo('Connected to Websocket at $_address');

      ws.pingInterval = const Duration(seconds: 5);
      _activeConnection = ws;
      _isConnecting = false;
      _isConnected = true;
      notifyListeners();

      ws.listen(
        _listenWS,
        onError: (dynamic err) => _handleDisconnect('Error: $err'),
        onDone: () => _handleDisconnect('Stream closed'),
      );
    } catch (e) {
      await _handleDisconnect('Connection failed: $e');
    }
  }

  void _listenWS(dynamic raw) {
    late FalconWSMessage message;
    try {
      message = FalconWSMessage.fromBytes(
        raw is Uint8List ? raw : Uint8List.fromList(raw as List<int>),
      );
    } catch (e, s) {
      logError('Failed to parse WS message: $e', s);
      return;
    }

    liveViewController.onNewWSMessage(message);
  }

  Future<void> _handleDisconnect([String? reason]) async {
    _isConnecting = false;
    _isConnected = false;

    await _activeConnection?.close();
    _activeConnection = null;

    notifyListeners();

    _reconnectTimer ??= Timer(
      const Duration(seconds: 1),
      _establishWSConnection,
    );

    liveViewController.clearBuffers();
  }

  Future<void> disconnect() async {
    await _activeConnection?.close();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    unawaited(_activeConnection?.close());
    super.dispose();
  }
}

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:falcon_gui/live_view/live_view_isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

final liveViewController = LiveViewController();

class LiveViewController extends ChangeNotifier {
  LiveViewController() {
    unawaited(_initWorkerIsolate());
    _initEngineTicker();
  }

  final Map<String, Float32List> optimizedRenderBuffers = {};
  final Map<String, int> renderBufferHeadIndices = {};

  bool isConnected = false;

  Ticker? _ticker;
  Isolate? _workerIsolate;
  SendPort? _isolateSendPort;
  late ReceivePort _controllerReceivePort;
  bool _isIsolateReady = false;

  double lastKnownScreenWidth = 1000;
  int visibleSamples = 90000;
  double yScaleMultiplier = 15000;

  void _initEngineTicker() {
    _ticker = Ticker(
      (_) => _tickLiveViewIsolate(),
      debugLabel: 'LiveViewIsolateTicker',
    );
    unawaited(_ticker?.start());
  }

  void _tickLiveViewIsolate() {
    if (!_isIsolateReady || _isolateSendPort == null) return;

    _isolateSendPort!.send(
      ProcessFrameCommand(
        visibleSamples: visibleSamples,
        renderWidth: lastKnownScreenWidth,
      ),
    );
  }

  Future<void> _initWorkerIsolate() async {
    _controllerReceivePort = ReceivePort();

    _workerIsolate = await Isolate.spawn(
      liveViewIsolate,
      LiveViewInitConfig(
        token: RootIsolateToken.instance!,
        controllerSendPort: _controllerReceivePort.sendPort,
        wsAddress: 'ws://0.0.0.0:5550',
      ),
    );

    _controllerReceivePort.listen((message) {
      if (message is SendPort) {
        _isolateSendPort = message;
        _isIsolateReady = true;
      } else if (message is LiveViewIsolateResponse) {
        final rawBytes = message.transferableBuffer.materialize();
        optimizedRenderBuffers[message.upstreamAddress] = rawBytes
            .asFloat32List();
        renderBufferHeadIndices[message.upstreamAddress] =
            message.latestWriteIndex;
        notifyListeners();
      } else if (message == 'CONNECTED') {
        isConnected = true;
        notifyListeners();
      } else if (message == 'CLEAR_BUFFERS') {
        isConnected = false;
        clearBuffers();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    _controllerReceivePort.close();
    _workerIsolate?.kill();
    super.dispose();
  }

  void clearBuffers() {
    optimizedRenderBuffers.clear();
    renderBufferHeadIndices.clear();
    notifyListeners();
  }
}

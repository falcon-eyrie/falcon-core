import 'dart:async';
import 'dart:isolate';

import 'package:falcon_gui/live_view/live_view_isolate.dart';
import 'package:falcon_gui/live_view/models/live_view_isolate_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final liveViewController = LiveViewController();

class LiveViewController extends ChangeNotifier {
  LiveViewController() {
    unawaited(_initWorkerIsolate());
  }

  final Map<String, LiveViewRenderParams> _lastSentRenderParams = {};
  final Map<String, List<Float32List>> optimizedRenderBuffers = {};
  Float32List optimizedEventLines = Float32List.fromList([]);

  int visibleSamples = 90000;

  bool isConnected = false;
  Isolate? _workerIsolate;
  SendPort? _isolateSendPort;
  late ReceivePort _controllerReceivePort;

  double getScaleMultiplier(String streamAddress) {
    return _lastSentRenderParams[streamAddress]?.yScaleMultiplier ?? 15000.0;
  }

  void updateLayoutDimensions({
    required String streamAddress,
    required double width,
    required double height,
  }) {
    final streamRenderParams = _lastSentRenderParams[streamAddress];
    if (streamRenderParams == null ||
        (streamRenderParams.renderWidth == width &&
            streamRenderParams.renderHeight == height)) {
      return;
    }
    _lastSentRenderParams[streamAddress] = streamRenderParams.copyWith(
      renderWidth: width,
      renderHeight: height,
    );

    _sendParamsToIsolate();
  }

  void updateProcessorScale(String streamAddress, double nextScale) {
    final streamRenderParams = _lastSentRenderParams[streamAddress];
    if (streamRenderParams == null) {
      return;
    }
    _lastSentRenderParams[streamAddress] = streamRenderParams.copyWith(
      yScaleMultiplier: nextScale,
    );

    _sendParamsToIsolate();
    notifyListeners();
  }

  void updateVisibleSamples(int nextValue) {
    visibleSamples = nextValue;

    _isolateSendPort!.send(visibleSamples);

    notifyListeners();
  }

  void _sendParamsToIsolate() {
    if (_isolateSendPort != null && _lastSentRenderParams.isNotEmpty) {
      _isolateSendPort!.send(_lastSentRenderParams);
    }
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
        _sendParamsToIsolate();
      } else if (message is LiveViewRenderData) {
        message.batchRenderBuffers.forEach((streamAddress, buffers) {
          optimizedRenderBuffers[streamAddress] = buffers.map((b) {
            final view = b.materialize().asUint8List();
            return Float32List.view(
              view.buffer,
              view.offsetInBytes,
              view.length ~/ 4,
            );
          }).toList();

          _lastSentRenderParams.putIfAbsent(
            streamAddress,
            LiveViewRenderParams.new,
          );
        });

        final eventView = message.events.materialize().asUint8List();
        optimizedEventLines = Float32List.view(
          eventView.buffer,
          eventView.offsetInBytes,
          eventView.length ~/ 4,
        );

        notifyListeners();
      } else if (message == 'CONNECTED') {
        isConnected = true;
        notifyListeners();
      } else if (message == 'CLEAR_BUFFERS') {
        isConnected = false;
        optimizedRenderBuffers.clear();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _controllerReceivePort.close();
    _workerIsolate?.kill();
    super.dispose();
  }
}

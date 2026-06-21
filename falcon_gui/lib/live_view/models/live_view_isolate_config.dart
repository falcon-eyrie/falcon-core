import 'dart:isolate';
import 'dart:ui';

class LiveViewInitConfig {
  const LiveViewInitConfig({
    required this.token,
    required this.controllerSendPort,
    required this.wsAddress,
  });
  final RootIsolateToken token;
  final SendPort controllerSendPort;
  final String wsAddress;
}

class LiveViewRenderData {
  const LiveViewRenderData({
    required this.batchRenderBuffers,
  });
  final Map<String, TransferableTypedData> batchRenderBuffers;
}

class LiveViewRenderParams {
  const LiveViewRenderParams({
    this.renderWidth = 1000,
    this.renderHeight = 1000,
    this.yScaleMultiplier = 10000,
  });

  final double renderWidth;
  final double renderHeight;
  final double yScaleMultiplier;

  LiveViewRenderParams copyWith({
    double? renderWidth,
    double? renderHeight,
    double? yScaleMultiplier,
  }) {
    return LiveViewRenderParams(
      renderWidth: renderWidth ?? this.renderWidth,
      renderHeight: renderHeight ?? this.renderHeight,
      yScaleMultiplier: yScaleMultiplier ?? this.yScaleMultiplier,
    );
  }
}

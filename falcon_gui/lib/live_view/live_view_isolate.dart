import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:falcon_gui/live_view/falcon_ws_message.dart';
import 'package:falcon_gui/live_view/signal_buffer.dart';
import 'package:flutter/services.dart';

class ProcessFrameCommand {
  ProcessFrameCommand({
    required this.visibleSamples,
    required this.renderWidth,
  });
  final int visibleSamples;
  final double renderWidth;
}

class LiveViewInitConfig {
  LiveViewInitConfig({
    required this.token,
    required this.controllerSendPort,
    required this.wsAddress,
  });
  final RootIsolateToken token;
  final SendPort controllerSendPort;
  final String wsAddress;
}

class DecimationJobResult {
  DecimationJobResult({
    required this.upstreamAddress,
    required this.latestWriteIndex,
    required this.transferableBuffer,
  });
  final String upstreamAddress;
  final int latestWriteIndex;
  final TransferableTypedData transferableBuffer;
}

void liveViewIsolate(
  LiveViewInitConfig config,
) {
  BackgroundIsolateBinaryMessenger.ensureInitialized(config.token);

  final commandPort = ReceivePort();
  config.controllerSendPort.send(commandPort.sendPort);

  final realtimeSignalBuffers = <String, SignalBuffer>{};
  WebSocket? activeConnection;
  Timer? reconnectTimer;

  late final void Function() establishWSConnection;

  void handleDisconnect() {
    unawaited(activeConnection?.close());
    activeConnection = null;
    realtimeSignalBuffers.clear();
    config.controllerSendPort.send('CLEAR_BUFFERS');
    reconnectTimer = Timer(const Duration(seconds: 1), () {
      reconnectTimer = null;
      establishWSConnection();
    });
  }

  establishWSConnection = () async {
    if (reconnectTimer != null) return;
    try {
      final ws = await WebSocket.connect(
        config.wsAddress,
      ).timeout(const Duration(seconds: 5));
      ws.pingInterval = const Duration(seconds: 5);
      activeConnection = ws;
      config.controllerSendPort.send('CONNECTED');

      ws.listen(
        (raw) {
          try {
            final bytes = raw is Uint8List
                ? raw
                : Uint8List.fromList(raw as List<int>);
            final wsMessage = FalconWSMessage.fromBytes(bytes);

            if (wsMessage.payload is MultiChannelSignalPayload) {
              final payload = wsMessage.payload as MultiChannelSignalPayload;
              realtimeSignalBuffers
                  .putIfAbsent(
                    wsMessage.upstreamAddress,
                    () => SignalBuffer(nchannels: payload.nchannels),
                  )
                  .appendSignalBuffer(payload);
            } else if (wsMessage.payload is EventPayload) {
              for (final buffer in realtimeSignalBuffers.values) {
                buffer.appendEvent(wsMessage.payload as EventPayload);
              }
            }
          } catch (_) {}
        },
        onError: (_) => handleDisconnect(),
        onDone: handleDisconnect,
      );
    } catch (_) {
      handleDisconnect();
    }
  };

  commandPort.listen((message) {
    if (message is! ProcessFrameCommand) return;

    final totalPixelCols = message.renderWidth.floor();
    if (message.visibleSamples < 2 || totalPixelCols <= 0) return;

    for (final entry in realtimeSignalBuffers.entries) {
      final address = entry.key;
      final buffer = entry.value;
      final channels = buffer.nchannels;
      if (channels == 0) continue;

      final maxSamples = buffer.bufferSize;
      final currentHeadIndex = buffer.latestWriteIndex % message.visibleSamples;
      final samplesPerPixel = message.visibleSamples / totalPixelCols;
      final totalSamplesAvailable = buffer.isBufferFull
          ? maxSamples
          : buffer.latestWriteIndex;
      final wipeGapSamples = (message.visibleSamples * 0.03).ceil().clamp(
        5,
        50,
      );

      final floatsPerChannel = totalPixelCols * 4;
      final vertexBuffer = Float32List(channels * floatsPerChannel);

      const minVal = -10.0;
      const range = 20.0;

      for (var col = 0; col < totalPixelCols; col++) {
        final startScreenIdx = (col * samplesPerPixel).floor();
        final endScreenIdx = ((col + 1) * samplesPerPixel).floor().clamp(
          0,
          message.visibleSamples,
        );
        final x = col.toDouble();

        for (var ch = 0; ch < channels; ch++) {
          var minValInPixel = double.infinity;
          var maxValInPixel = double.negativeInfinity;
          var hasValidSamples = false;
          var inWipeGap = false;

          for (
            var screenIdx = startScreenIdx;
            screenIdx < endScreenIdx;
            screenIdx++
          ) {
            if (screenIdx > currentHeadIndex &&
                screenIdx < (currentHeadIndex + wipeGapSamples)) {
              inWipeGap = true;
              break;
            }

            final distanceBehindHead =
                (currentHeadIndex - screenIdx + message.visibleSamples) %
                message.visibleSamples;
            final targetDataIndex =
                buffer.latestWriteIndex - distanceBehindHead;

            if (targetDataIndex < 0 ||
                targetDataIndex >= totalSamplesAvailable) {
              continue;
            }

            final ringBufferIdx = targetDataIndex % maxSamples;
            final flatIndex = (ringBufferIdx * channels) + ch;
            final value = buffer.dataView[flatIndex];

            if (value < minValInPixel) minValInPixel = value;
            if (value > maxValInPixel) maxValInPixel = value;
            hasValidSamples = true;
          }

          final baseOffset = (ch * floatsPerChannel) + (col * 4);

          if (inWipeGap || !hasValidSamples) {
            vertexBuffer[baseOffset] = -1.0;
            vertexBuffer[baseOffset + 1] = -1.0;
            vertexBuffer[baseOffset + 2] = -1.0;
            vertexBuffer[baseOffset + 3] = -1.0;
            continue;
          }

          vertexBuffer[baseOffset] = x;
          vertexBuffer[baseOffset + 1] = (minValInPixel - minVal) / range;
          vertexBuffer[baseOffset + 2] = x;
          vertexBuffer[baseOffset + 3] = (maxValInPixel - minVal) / range;
        }
      }

      config.controllerSendPort.send(
        DecimationJobResult(
          upstreamAddress: address,
          latestWriteIndex: buffer.latestWriteIndex,
          transferableBuffer: TransferableTypedData.fromList([vertexBuffer]),
        ),
      );
    }
  });

  establishWSConnection();
}

import 'dart:isolate';
import 'dart:typed_data';

import 'package:falcon_gui/live_view/models/live_view_isolate_config.dart';
import 'package:falcon_gui/live_view/signal_parser.dart';

class PlotDrawer {
  static void generateRenderPayload({
    required SendPort sendPort,
    required Map<String, LiveViewRenderParams> renderParams,
    required int visibleSamples,
  }) {
    final accumulatedBuffers = <String, List<TransferableTypedData>>{};

    for (final streamKey in SignalParser.historyBuffers.keys) {
      _generateSharedCanvasRenderBuffers(
        streamKey,
        renderParams,
        visibleSamples,
        accumulatedBuffers,
      );
    }

    // Compute absolute synchronized time pixel tracks
    final eventXOffsets = _computeEventPixelCoordinates(
      renderParams,
      visibleSamples,
    );

    sendPort.send(
      LiveViewRenderData(
        batchRenderBuffers: accumulatedBuffers,
        events: TransferableTypedData.fromList([eventXOffsets]),
      ),
    );
  }

  static void _generateSharedCanvasRenderBuffers(
    String streamKey,
    Map<String, LiveViewRenderParams> renderParams,
    int visibleSamples,
    Map<String, List<TransferableTypedData>> accumulatedBuffers,
  ) {
    final p = renderParams[streamKey] ?? const LiveViewRenderParams();
    final cols = p.renderWidth <= 0 ? 1000 : p.renderWidth.floor();
    final viewHeight = p.renderHeight <= 0 ? 250.0 : p.renderHeight;

    final writeIdx = SignalParser.historyWriteIndices[streamKey] ?? 0;
    final history = SignalParser.historyBuffers[streamKey];
    final tsHistory = SignalParser.historyTimestamps[streamKey];

    if (history == null || tsHistory == null || cols <= 0) return;

    final totalChannels =
        history.length ~/ SignalParser.kAllocatedSampleBufferSize;
    final halfHeight = viewHeight / 2.0;

    final channelVertexLists = List<Float32List>.generate(
      totalChannels,
      (_) => Float32List(cols * 4),
    );

    final lastWrittenIdx =
        (writeIdx - 1 + SignalParser.kAllocatedSampleBufferSize) %
        SignalParser.kAllocatedSampleBufferSize;
    final latestTime = tsHistory[lastWrittenIdx];
    final oldestInViewIdx =
        (writeIdx - visibleSamples + SignalParser.kAllocatedSampleBufferSize) %
        SignalParser.kAllocatedSampleBufferSize;
    final oldestTime = tsHistory[oldestInViewIdx];

    final totalTimeSpan = latestTime - oldestTime;
    final timePerPixel = totalTimeSpan / cols;

    var historySearchIdx = oldestInViewIdx;

    for (var col = 0; col < cols; col++) {
      final vIdx = col * 4;
      final x1 = col.toDouble();
      final x2 = (col + 1).toDouble();

      final targetTime1 = oldestTime + (col * timePerPixel).floor();
      final targetTime2 = oldestTime + ((col + 1) * timePerPixel).floor();

      while (tsHistory[historySearchIdx] < targetTime1 &&
          historySearchIdx != lastWrittenIdx) {
        historySearchIdx =
            (historySearchIdx + 1) % SignalParser.kAllocatedSampleBufferSize;
      }
      final idx1 = historySearchIdx;

      while (tsHistory[historySearchIdx] < targetTime2 &&
          historySearchIdx != lastWrittenIdx) {
        historySearchIdx =
            (historySearchIdx + 1) % SignalParser.kAllocatedSampleBufferSize;
      }
      final idx2 = historySearchIdx;

      final flatIdx1 = idx1 * totalChannels;
      final flatIdx2 = idx2 * totalChannels;

      for (var ch = 0; ch < totalChannels; ch++) {
        final y1 = halfHeight - (history[flatIdx1 + ch] * p.yScaleMultiplier);
        final y2 = halfHeight - (history[flatIdx2 + ch] * p.yScaleMultiplier);

        final list = channelVertexLists[ch];
        list[vIdx] = x1;
        list[vIdx + 1] = y1;
        list[vIdx + 2] = x2;
        list[vIdx + 3] = y2;
      }
    }

    accumulatedBuffers[streamKey] = channelVertexLists
        .map((list) => TransferableTypedData.fromList([list]))
        .toList();
  }

  static Float32List _computeEventPixelCoordinates(
    Map<String, LiveViewRenderParams> renderParams,
    int visibleSamples,
  ) {
    if (SignalParser.capturedEventTimestamps.isEmpty ||
        SignalParser.historyTimestamps.isEmpty) {
      return Float32List(0);
    }

    final primaryKey = SignalParser.historyTimestamps.keys.first;
    final tsHistory = SignalParser.historyTimestamps[primaryKey]!;
    final writeIdx = SignalParser.historyWriteIndices[primaryKey] ?? 0;

    final p = renderParams[primaryKey] ?? const LiveViewRenderParams();
    final cols = p.renderWidth <= 0 ? 1000 : p.renderWidth.floor();

    final lastWrittenIdx =
        (writeIdx - 1 + SignalParser.kAllocatedSampleBufferSize) %
        SignalParser.kAllocatedSampleBufferSize;
    final latestTime = tsHistory[lastWrittenIdx];
    final oldestInViewIdx =
        (writeIdx - visibleSamples + SignalParser.kAllocatedSampleBufferSize) %
        SignalParser.kAllocatedSampleBufferSize;
    final oldestTime = tsHistory[oldestInViewIdx];
    final totalTimeSpan = latestTime - oldestTime;

    if (totalTimeSpan <= 0) return Float32List(0);

    final validXOffsets = <double>[];
    for (final eventTime in SignalParser.capturedEventTimestamps) {
      if (eventTime >= oldestTime && eventTime <= latestTime) {
        final xPixel = ((eventTime - oldestTime) / totalTimeSpan) * cols;
        validXOffsets.add(xPixel);
      }
    }

    return Float32List.fromList(validXOffsets);
  }
}

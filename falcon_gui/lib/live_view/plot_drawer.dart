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

    var maxValGlobal = 0.0001;
    var oldestTimeGlobal = double.infinity;
    var latestTimeGlobal = -double.infinity;
    var streamsFound = false;

    for (final streamKey in SignalParser.historyBuffers.keys) {
      final writeIdx = SignalParser.historyWriteIndices[streamKey] ?? 0;
      final tsHistory = SignalParser.historyTimestamps[streamKey];
      final history = SignalParser.historyBuffers[streamKey];

      if (history == null || tsHistory == null || visibleSamples <= 1) continue;

      streamsFound = true;

      final lastWrittenIdx =
          (writeIdx - 1 + SignalParser.kAllocatedSampleBufferSize) %
          SignalParser.kAllocatedSampleBufferSize;
      final oldestInViewIdx =
          (writeIdx -
              visibleSamples +
              SignalParser.kAllocatedSampleBufferSize) %
          SignalParser.kAllocatedSampleBufferSize;
      final isBufferFull =
          SignalParser.historyWriteIndices[streamKey] != null &&
          writeIdx >= visibleSamples;
      if (!isBufferFull) {
        return;
      }
      final streamOldest = tsHistory[oldestInViewIdx].toDouble();
      final streamLatest = tsHistory[lastWrittenIdx].toDouble();

      if (streamOldest < oldestTimeGlobal) oldestTimeGlobal = streamOldest;
      if (streamLatest > latestTimeGlobal) latestTimeGlobal = streamLatest;

      final totalChannels =
          history.length ~/ SignalParser.kAllocatedSampleBufferSize;
      var scanIdx = oldestInViewIdx;
      for (var s = 0; s < visibleSamples; s++) {
        final flatBase = scanIdx * totalChannels;
        for (var ch = 0; ch < totalChannels; ch++) {
          final val = history[flatBase + ch].abs();
          if (val > maxValGlobal) maxValGlobal = val;
        }
        scanIdx = (scanIdx + 1) % SignalParser.kAllocatedSampleBufferSize;
      }
    }

    if (!streamsFound || oldestTimeGlobal >= latestTimeGlobal) {
      oldestTimeGlobal = 0.0;
      latestTimeGlobal = 1.0;
    }

    for (final streamKey in SignalParser.historyBuffers.keys) {
      _generateSharedCanvasSmoothBuffersLocked(
        streamKey: streamKey,
        renderParams: renderParams,
        visibleSamples: visibleSamples,
        globalOldestTime: oldestTimeGlobal,
        globalLatestTime: latestTimeGlobal,
        accumulatedBuffers: accumulatedBuffers,
      );
    }

    final primaryKey = SignalParser.historyTimestamps.keys.firstOrNull ?? '';
    final p = renderParams[primaryKey] ?? const LiveViewRenderParams();
    final width = p.renderWidth <= 0 ? 1000.0 : p.renderWidth;
    final height = p.renderHeight <= 0 ? 1000.0 : p.renderHeight;

    final eventXOffsets = _computeEventPixelCoordinatesLocked(
      width,
      oldestTimeGlobal,
      latestTimeGlobal,
    );

    final gridLineVertices = Float32List(5 * 4 + 10 * 4);
    final yTickValues = <double>[];
    final xTickValues = <double>[];

    _calculateGridAndLabels(
      width: width,
      height: height,
      oldestTime: oldestTimeGlobal,
      latestTime: latestTimeGlobal,
      maxVal: maxValGlobal,
      vertexBuffer: gridLineVertices,
      yTicks: yTickValues,
      xTicks: xTickValues,
    );

    sendPort.send(
      LiveViewRenderData(
        batchRenderBuffers: accumulatedBuffers,
        events: TransferableTypedData.fromList([eventXOffsets]),
        grid: TransferableTypedData.fromList([gridLineVertices]),
        xTickValues: xTickValues,
        yTickValues: yTickValues,
      ),
    );
  }

  static void _calculateGridAndLabels({
    required double width,
    required double height,
    required double oldestTime,
    required double latestTime,
    required double maxVal,
    required Float32List vertexBuffer,
    required List<double> yTicks,
    required List<double> xTicks,
  }) {
    var vOffset = 0;

    final yStepValue = (maxVal * 2) / 4;
    final yPixelStep = height / 4;
    for (var i = 0; i < 5; i++) {
      final yPixel = i * yPixelStep;
      final yDataValue = maxVal - (i * yStepValue);
      yTicks.add(yDataValue);

      vertexBuffer[vOffset++] = 0.0;
      vertexBuffer[vOffset++] = yPixel;
      vertexBuffer[vOffset++] = width;
      vertexBuffer[vOffset++] = yPixel;
    }

    final xTimeStep = (latestTime - oldestTime) / 9;
    final xPixelStep = width / 9;
    for (var i = 0; i < 10; i++) {
      final xPixel = i * xPixelStep;
      final xTimeValue = oldestTime + (i * xTimeStep);
      xTicks.add(xTimeValue);

      vertexBuffer[vOffset++] = xPixel;
      vertexBuffer[vOffset++] = 0.0;
      vertexBuffer[vOffset++] = xPixel;
      vertexBuffer[vOffset++] = height;
    }
  }

  static void _generateSharedCanvasSmoothBuffersLocked({
    required String streamKey,
    required Map<String, LiveViewRenderParams> renderParams,
    required int visibleSamples,
    required double globalOldestTime,
    required double globalLatestTime,
    required Map<String, List<TransferableTypedData>> accumulatedBuffers,
  }) {
    final p = renderParams[streamKey] ?? const LiveViewRenderParams();
    final cols = p.renderWidth <= 0 ? 1000 : p.renderWidth.floor();
    final viewHeight = p.renderHeight <= 0 ? 1000.0 : p.renderHeight;

    final writeIdx = SignalParser.historyWriteIndices[streamKey] ?? 0;
    final history = SignalParser.historyBuffers[streamKey];
    final tsHistory = SignalParser.historyTimestamps[streamKey];

    if (history == null ||
        tsHistory == null ||
        cols <= 0 ||
        visibleSamples <= 1) {
      return;
    }

    final totalChannels =
        history.length ~/ SignalParser.kAllocatedSampleBufferSize;

    final channelVertexLists = List<Float32List>.generate(
      totalChannels,
      (_) => Float32List(cols * 4),
    );

    final oldestInViewIdx =
        (writeIdx - visibleSamples + SignalParser.kAllocatedSampleBufferSize) %
        SignalParser.kAllocatedSampleBufferSize;

    var localMaxVal = 0.000000001;
    var scanIdx = oldestInViewIdx;
    for (var s = 0; s < visibleSamples; s++) {
      final flatBase = scanIdx * totalChannels;
      for (var ch = 0; ch < totalChannels; ch++) {
        final val = history[flatBase + ch].abs();
        if (val > localMaxVal) localMaxVal = val;
      }
      scanIdx = (scanIdx + 1) % SignalParser.kAllocatedSampleBufferSize;
    }

    final midY = viewHeight / 2.0;
    final scalingFactor = midY / localMaxVal;

    final totalTimeSpan = globalLatestTime - globalOldestTime;
    final timeScale = totalTimeSpan > 0 ? (cols - 1) / totalTimeSpan : 1.0;

    final rawStride = (visibleSamples - 1) / (cols - 1);
    final initialX =
        (tsHistory[oldestInViewIdx] - globalOldestTime) * timeScale;

    var lastX = initialX;
    final lastY = Float64List(totalChannels);
    final flatStart = oldestInViewIdx * totalChannels;
    for (var ch = 0; ch < totalChannels; ch++) {
      lastY[ch] = midY - (history[flatStart + ch] * scalingFactor);
    }

    for (var col = 1; col < cols; col++) {
      final targetSampleIndex = col * rawStride;
      final floorIdx = targetSampleIndex.floor();
      final fraction = targetSampleIndex - floorIdx;

      final s1Idx =
          (oldestInViewIdx + floorIdx) %
          SignalParser.kAllocatedSampleBufferSize;
      final s2Idx = (s1Idx + 1) % SignalParser.kAllocatedSampleBufferSize;

      final t1 = tsHistory[s1Idx];
      final t2 = tsHistory[s2Idx];
      final sampleTime = t1 + (t2 - t1) * fraction;

      final currentX = (sampleTime - globalOldestTime) * timeScale;
      final vIdx = (col - 1) * 4;

      final flatIdx1 = s1Idx * totalChannels;
      final flatIdx2 = s2Idx * totalChannels;

      for (var ch = 0; ch < totalChannels; ch++) {
        final y1 = history[flatIdx1 + ch];
        final y2 = history[flatIdx2 + ch];
        final blendedVal = y1 + (y2 - y1) * fraction;
        final currentY = midY - (blendedVal * scalingFactor);

        final list = channelVertexLists[ch];
        list[vIdx] = lastX;
        list[vIdx + 1] = lastY[ch];
        list[vIdx + 2] = currentX;
        list[vIdx + 3] = currentY;

        lastY[ch] = currentY;
      }

      lastX = currentX;
    }

    final finalVIdx = (cols - 1) * 4;
    for (var ch = 0; ch < totalChannels; ch++) {
      final list = channelVertexLists[ch];
      list[finalVIdx] = lastX;
      list[finalVIdx + 1] = lastY[ch];
      list[finalVIdx + 2] = lastX;
      list[finalVIdx + 3] = lastY[ch];
    }

    accumulatedBuffers[streamKey] = channelVertexLists
        .map((list) => TransferableTypedData.fromList([list]))
        .toList();
  }

  static Float32List _computeEventPixelCoordinatesLocked(
    double renderWidth,
    double globalOldestTime,
    double globalLatestTime,
  ) {
    if (SignalParser.capturedEventTimestamps.isEmpty ||
        SignalParser.historyTimestamps.isEmpty) {
      return Float32List(0);
    }

    final totalTimeSpan = globalLatestTime - globalOldestTime;
    if (totalTimeSpan <= 0) return Float32List(0);

    final validXOffsets = <double>[];
    for (final eventTime in SignalParser.capturedEventTimestamps) {
      if (eventTime >= globalOldestTime && eventTime <= globalLatestTime) {
        final xPixel =
            ((eventTime - globalOldestTime) / totalTimeSpan) * renderWidth;
        validXOffsets.add(xPixel);
      }
    }

    return Float32List.fromList(validXOffsets);
  }
}

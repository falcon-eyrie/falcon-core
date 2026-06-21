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
    var oldestTimeGlobal = 0.0;
    var latestTimeGlobal = 0.0;
    var computedGlobalBounds = false;

    for (final streamKey in SignalParser.historyBuffers.keys) {
      final bounds = _generateSharedCanvasRenderBuffers(
        streamKey,
        renderParams,
        visibleSamples,
        accumulatedBuffers,
      );
      if (bounds != null) {
        if (!computedGlobalBounds) {
          maxValGlobal = bounds.maxVal;
          oldestTimeGlobal = bounds.oldestTime;
          latestTimeGlobal = bounds.latestTime;
          computedGlobalBounds = true;
        } else {
          if (bounds.maxVal > maxValGlobal) maxValGlobal = bounds.maxVal;
          if (bounds.oldestTime < oldestTimeGlobal) {
            oldestTimeGlobal = bounds.oldestTime;
          }
          if (bounds.latestTime > latestTimeGlobal) {
            latestTimeGlobal = bounds.latestTime;
          }
        }
      }
    }

    final primaryKey = SignalParser.historyTimestamps.keys.firstOrNull ?? '';
    final p = renderParams[primaryKey] ?? const LiveViewRenderParams();
    final width = p.renderWidth <= 0 ? 1000.0 : p.renderWidth;
    final height = p.renderHeight <= 0 ? 1000.0 : p.renderHeight;

    final eventXOffsets = _computeEventPixelCoordinates(width, visibleSamples);

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

  static _StreamBounds? _generateSharedCanvasRenderBuffers(
    String streamKey,
    Map<String, LiveViewRenderParams> renderParams,
    int visibleSamples,
    Map<String, List<TransferableTypedData>> accumulatedBuffers,
  ) {
    final p = renderParams[streamKey] ?? const LiveViewRenderParams();
    final cols = p.renderWidth <= 0 ? 1000 : p.renderWidth.floor();
    final viewHeight = p.renderHeight <= 0 ? 1000.0 : p.renderHeight;

    final writeIdx = SignalParser.historyWriteIndices[streamKey] ?? 0;
    final history = SignalParser.historyBuffers[streamKey];
    final tsHistory = SignalParser.historyTimestamps[streamKey];

    if (history == null || tsHistory == null || cols <= 0) return null;

    final totalChannels =
        history.length ~/ SignalParser.kAllocatedSampleBufferSize;
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

    var maxVal = 0.000000001;
    var scanIdx = oldestInViewIdx;

    for (var s = 0; s < visibleSamples; s++) {
      final flatBase = scanIdx * totalChannels;
      for (var ch = 0; ch < totalChannels; ch++) {
        final val = history[flatBase + ch].abs();
        if (val > maxVal) maxVal = val;
      }
      scanIdx = (scanIdx + 1) % SignalParser.kAllocatedSampleBufferSize;
    }

    final midY = viewHeight / 2.0;
    final scalingFactor = midY / maxVal;

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
        final y1 = midY - (history[flatIdx1 + ch] * scalingFactor);
        final y2 = midY - (history[flatIdx2 + ch] * scalingFactor);

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

    return _StreamBounds(
      maxVal: maxVal,
      oldestTime: oldestTime.toDouble(),
      latestTime: latestTime.toDouble(),
    );
  }

  static Float32List _computeEventPixelCoordinates(
    double renderWidth,
    int visibleSamples,
  ) {
    if (SignalParser.capturedEventTimestamps.isEmpty ||
        SignalParser.historyTimestamps.isEmpty) {
      return Float32List(0);
    }

    final primaryKey = SignalParser.historyTimestamps.keys.first;
    final tsHistory = SignalParser.historyTimestamps[primaryKey]!;
    final writeIdx = SignalParser.historyWriteIndices[primaryKey] ?? 0;

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
        final xPixel = ((eventTime - oldestTime) / totalTimeSpan) * renderWidth;
        validXOffsets.add(xPixel);
      }
    }

    return Float32List.fromList(validXOffsets);
  }
}

class _StreamBounds {
  const _StreamBounds({
    required this.maxVal,
    required this.oldestTime,
    required this.latestTime,
  });
  final double maxVal;
  final double oldestTime;
  final double latestTime;
}

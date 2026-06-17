import 'package:falcon_gui/live_view/live_view_controller.dart';
import 'package:flutter/material.dart';

class LivePlotPainter extends CustomPainter {
  LivePlotPainter({
    required this.signalBuffer,
    required this.visibleSamples,
    required this.yScaleMultiplier,
  });

  final SignalBuffer signalBuffer;
  final int visibleSamples;
  final double yScaleMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final channels = signalBuffer.nchannels;
    final maxSamples = signalBuffer.bufferSize;

    if (channels == 0 || visibleSamples < 2) return;

    final latestWrite = signalBuffer.latestWriteIndex;
    if (latestWrite < 0) return;

    final currentHeadIndex = latestWrite % visibleSamples;

    // 1. Render data lines
    _drawEKGSignalTraces(
      canvas: canvas,
      size: size,
      channels: channels,
      maxSamples: maxSamples,
      currentHeadIndex: currentHeadIndex,
    );

    // 2. Draw the vertical playback/writing cursor line
    _drawSignalCursor(
      canvas: canvas,
      size: size,
      currentHeadIndex: currentHeadIndex,
    );

    // 3. Overlay vertical event marker tracks
    _drawNeuralEvents(
      canvas: canvas,
      size: size,
      currentHeadIndex: currentHeadIndex,
    );
  }

  void _drawSignalCursor({
    required Canvas canvas,
    required Size size,
    required int currentHeadIndex,
  }) {
    final stepX = size.width / (visibleSamples - 1);
    final cursorX = currentHeadIndex * stepX;

    final cursorPaint = Paint()
      ..color = Colors.white
          .withAlpha(200) // White line with opacity
      ..strokeWidth =
          2.0 // Slightly thicker than data line
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, size.height),
      cursorPaint,
    );
  }

  void _drawEKGSignalTraces({
    required Canvas canvas,
    required Size size,
    required int channels,
    required int maxSamples,
    required int currentHeadIndex,
  }) {
    final rowHeight = size.height / channels;
    final stepX = size.width / (visibleSamples - 1);

    final wipeGapSamples = (visibleSamples * 0.03).ceil().clamp(5, 50);

    const maxVal = 10.0;
    const minVal = -10.0;
    const range = maxVal - minVal;

    final paths = List<Path>.generate(channels, (_) => Path());
    final paints = List<Paint>.generate(
      channels,
      (c) => Paint()
        ..color = Colors.accents[c % Colors.accents.length]
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final data = signalBuffer.dataView;
    final totalSamplesAvailable = signalBuffer.isBufferFull
        ? maxSamples
        : signalBuffer.latestWriteIndex;

    final int stride = (visibleSamples / (size.width * 2)).floor().clamp(
      1,
      1000,
    );

    for (var screenIdx = 0; screenIdx < visibleSamples; screenIdx += stride) {
      final distanceBehindHead =
          (currentHeadIndex - screenIdx + visibleSamples) % visibleSamples;
      final targetDataIndex =
          signalBuffer.latestWriteIndex - distanceBehindHead;

      if (targetDataIndex < 0 || targetDataIndex >= totalSamplesAvailable) {
        continue;
      }

      if (screenIdx > currentHeadIndex &&
          screenIdx < (currentHeadIndex + wipeGapSamples)) {
        continue;
      }

      final ringBufferIdx = targetDataIndex % maxSamples;
      final x = screenIdx * stepX;

      for (var ch = 0; ch < channels; ch++) {
        final flatIndex = (ringBufferIdx * channels) + ch;
        final value = data[flatIndex];

        final midY = (ch * rowHeight) + (rowHeight / 2);
        final scaleY = (rowHeight / 2) * 0.8 * yScaleMultiplier;
        final normalizedValue = (value - minVal) / range;
        final y = midY - ((normalizedValue - 0.5) * 2 * scaleY);

        if (screenIdx == 0 ||
            (screenIdx >= currentHeadIndex + wipeGapSamples &&
                screenIdx < currentHeadIndex + wipeGapSamples + stride) ||
            (screenIdx > currentHeadIndex &&
                screenIdx - stride <= currentHeadIndex)) {
          paths[ch].moveTo(x, y);
        } else {
          paths[ch].lineTo(x, y);
        }
      }
    }

    for (var ch = 0; ch < channels; ch++) {
      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(0, ch * rowHeight, size.width, rowHeight))
        ..drawPath(paths[ch], paints[ch])
        ..restore();
    }
  }

  void _drawNeuralEvents({
    required Canvas canvas,
    required Size size,
    required int currentHeadIndex,
  }) {
    final maxSamples = signalBuffer.bufferSize;
    final latestWrite = signalBuffer.latestWriteIndex;
    if (latestWrite < 2) return;

    final newestSampleIndex = (latestWrite - 1 + maxSamples) % maxSamples;
    final availableSamples = signalBuffer.isBufferFull
        ? maxSamples
        : latestWrite;
    final samplesToRender = visibleSamples < availableSamples
        ? visibleSamples
        : availableSamples;
    final oldestSampleIndex =
        (latestWrite - samplesToRender + maxSamples) % maxSamples;

    final physicalStartTime = signalBuffer.timestampView[oldestSampleIndex];
    final physicalEndTime = signalBuffer.timestampView[newestSampleIndex];
    final microsecondWindowSize = physicalEndTime - physicalStartTime;

    if (microsecondWindowSize <= 0) return;

    final linePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.5;

    final stepX = size.width / (visibleSamples - 1);

    for (final event in signalBuffer.events) {
      final eventTime = event.closestSampleTimestamp;

      if (eventTime >= physicalStartTime && eventTime <= physicalEndTime) {
        final timeBehindHead = physicalEndTime - eventTime;
        final totalDuration = physicalEndTime - physicalStartTime;

        final samplesBehindHead =
            (timeBehindHead / totalDuration * samplesToRender).round();

        final screenIdx =
            (currentHeadIndex - samplesBehindHead + visibleSamples) %
            visibleSamples;
        final x = screenIdx * stepX;

        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        _drawEventLabel(canvas, event.eventName, x);
      }
    }
  }

  void _drawEventLabel(Canvas canvas, String name, double x) {
    TextPainter(
        text: TextSpan(
          text: ' $name',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, Offset(x + 2, 4));
  }

  @override
  bool shouldRepaint(covariant LivePlotPainter old) => true;
}

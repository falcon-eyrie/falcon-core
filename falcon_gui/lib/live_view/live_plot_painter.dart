import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

class LivePlotPainter extends CustomPainter {
  LivePlotPainter({
    required this.optimizedVertexBuffer,
    required this.channels,
    required this.currentHeadIndex,
    required this.visibleSamples,
    required this.yScaleMultiplier,
  });

  final Float32List? optimizedVertexBuffer;
  final int channels;
  final int currentHeadIndex;
  final int visibleSamples;
  final double yScaleMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    if (channels == 0 || visibleSamples < 2 || optimizedVertexBuffer == null) {
      return;
    }

    _drawSignalsOptimized(canvas, size);
    _drawSignalCursor(canvas, size);
  }

  void _drawSignalsOptimized(Canvas canvas, Size size) {
    final rowHeight = size.height / channels;
    final totalPixelCols = size.width.floor();
    final floatsPerChannel = totalPixelCols * 4;

    final paint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final totalBytes = floatsPerChannel * 4;

    for (var ch = 0; ch < channels; ch++) {
      paint.color = Colors.accents[ch % Colors.accents.length];

      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(0, ch * rowHeight, size.width, rowHeight));

      final byteOffset = ch * totalBytes;
      final channelView = Float32List.view(
        optimizedVertexBuffer!.buffer,
        byteOffset,
        floatsPerChannel,
      );

      // Temporary local draw buffer to avoid modifying the cached
      // isolate buffer
      final drawBuffer = Float32List(floatsPerChannel);
      final midY = (ch * rowHeight) + (rowHeight / 2);
      final scaleY = (rowHeight / 2) * 0.8 * yScaleMultiplier;

      for (var i = 0; i < floatsPerChannel; i += 4) {
        if (channelView[i] < 0) {
          // Maintain line gaps (e.g., inside the wipe gap)
          drawBuffer[i] = -1.0;
          drawBuffer[i + 1] = -1.0;
          drawBuffer[i + 2] = -1.0;
          drawBuffer[i + 3] = -1.0;
          continue;
        }

        drawBuffer[i] = channelView[i];
        drawBuffer[i + 1] = midY - ((channelView[i + 1] - 0.5) * 2 * scaleY);
        drawBuffer[i + 2] = channelView[i + 2];
        drawBuffer[i + 3] = midY - ((channelView[i + 3] - 0.5) * 2 * scaleY);
      }

      // Hardware-accelerated drawing
      canvas
        ..drawRawPoints(PointMode.lines, drawBuffer, paint)
        ..restore();
    }
  }

  void _drawSignalCursor(Canvas canvas, Size size) {
    final stepX = size.width / (visibleSamples - 1);
    final currentHeadSampleIndex = currentHeadIndex % visibleSamples;
    final cursorX = currentHeadSampleIndex * stepX;

    final cursorPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, size.height),
      cursorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant LivePlotPainter oldDelegate) {
    return oldDelegate.optimizedVertexBuffer != optimizedVertexBuffer ||
        oldDelegate.currentHeadIndex != currentHeadIndex ||
        oldDelegate.yScaleMultiplier != yScaleMultiplier;
  }
}

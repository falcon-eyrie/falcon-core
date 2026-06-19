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
    final totalBytesPerChannel = floatsPerChannel * 4;

    final paint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final midY = rowHeight / 2;
    final scaleY = rowHeight * 0.4 * yScaleMultiplier;

    for (var ch = 0; ch < channels; ch++) {
      paint.color = Colors.accents[ch % Colors.accents.length];

      final topY = ch * rowHeight;

      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(0, topY, size.width, rowHeight))
        // Push the canvas to the row track position
        ..translate(0, topY + midY);

      final byteOffset = ch * totalBytesPerChannel;

      // Zero-Copy: Create a direct window into transferred isolate data
      final channelView = Float32List.view(
        optimizedVertexBuffer!.buffer,
        optimizedVertexBuffer!.offsetInBytes + byteOffset,
        floatsPerChannel,
      );

      // Zero-Allocation Mutation: Modify the data in place.
      // Since this data was received from TransferableTypedData,
      // the UI thread owns it uniquely. Modifying it is safe and free.
      for (var i = 0; i < floatsPerChannel; i += 4) {
        if (channelView[i] < 0) continue; // Skip wipe gaps

        // Map the isolate's normalized (0.0 to 1.0) value directly to
        // rendering space. This math is done in place without
        // duplicating arrays
        channelView[i + 1] = -((channelView[i + 1] - 0.5) * 2 * scaleY);
        channelView[i + 3] = -((channelView[i + 3] - 0.5) * 2 * scaleY);
      }

      // Direct GPU hardware-accelerated drawing
      canvas
        ..drawRawPoints(PointMode.lines, channelView, paint)
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

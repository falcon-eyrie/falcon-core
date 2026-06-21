import 'dart:typed_data';
import 'dart:ui';

import 'package:falcon_gui/live_view/live_view_controller.dart';
import 'package:falcon_gui/live_view/widgets/param_sliders.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class LiveView extends StatefulWidget {
  const LiveView({super.key});

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  var _isFrozen = false;

  final _emptyListenable = Listenable.merge([]);
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _isFrozen ? _emptyListenable : liveViewController,
      builder: (context, _) {
        if (!liveViewController.isConnected) {
          return Center(
            child: Text(
              'Connecting to WebSocket server...',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          );
        }

        final renderBuffers = liveViewController.optimizedRenderBuffers;
        if (renderBuffers.isEmpty) {
          return Center(
            child: Text(
              'Connected. Waiting for stream data...',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          );
        }
        return Stack(
          children: [
            Column(
              children: renderBuffers.keys.map((streamAddress) {
                return Expanded(
                  child: _SignalCard(streamAddress: streamAddress),
                );
              }).toList(),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isFrozen = !_isFrozen),
                    icon: Icon(
                      _isFrozen
                          ? RemixIcons.play_circle_fill
                          : RemixIcons.pause_circle_fill,
                    ),
                  ),
                  const ViewParamSliders(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.streamAddress});
  final String streamAddress;

  @override
  Widget build(BuildContext context) {
    final optimizedData =
        liveViewController.optimizedRenderBuffers[streamAddress];

    return SizedBox(
      height: 250,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                streamAddress,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        liveViewController.updateLayoutDimensions(
                          streamAddress: streamAddress,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        );
                        if (optimizedData == null) {
                          return const Text('Buffer is empty.');
                        }
                        return RepaintBoundary(
                          child: CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _LivePlotPainter(
                              vertexBuffers: optimizedData,
                              eventXCoordinates:
                                  liveViewController.optimizedEventLines,
                              gridLines: liveViewController.optimizedGridLines,
                              xTickValues: liveViewController.xTickValues,
                              yTickValues: liveViewController.yTickValues,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePlotPainter extends CustomPainter {
  const _LivePlotPainter({
    required this.vertexBuffers,
    required this.eventXCoordinates,
    required this.gridLines,
    required this.xTickValues,
    required this.yTickValues,
  });

  final List<Float32List> vertexBuffers;
  final Float32List eventXCoordinates;
  final Float32List gridLines;
  final List<double> xTickValues;
  final List<double> yTickValues;

  static const List<Color> _channelColors = [
    Color(0xFF34BCFB),
    Color(0xFFFFC252),
    Color(0xFFFF5252),
    Color(0xFF7669F0),
    Color(0xFF9BE37C),
    Color(0xFFF069C5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (gridLines.isNotEmpty) {
      final gridPaint = Paint()
        ..color = const Color.fromARGB(255, 149, 144, 144)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRawPoints(PointMode.lines, gridLines, gridPaint);
    }

    _paintAxisLabels(canvas, size);

    final basePaint = Paint()
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < vertexBuffers.length; i++) {
      if (vertexBuffers[i].isEmpty) continue;
      canvas.drawRawPoints(
        PointMode.lines,
        vertexBuffers[i],
        basePaint..color = _channelColors[i % _channelColors.length],
      );
    }

    final eventPaint = Paint()
      ..color = const Color.fromARGB(255, 235, 101, 101)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < eventXCoordinates.length; i++) {
      final x = eventXCoordinates[i];
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), eventPaint);
    }
  }

  void _paintAxisLabels(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Color(0xFF716565),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    final totalYLines = yTickValues.length;
    final yPixelStep = size.height / (totalYLines - 1);

    var yValScale = 1;
    var scaledVal = yTickValues[0];
    while (scaledVal < 100) {
      yValScale *= 10;
      scaledVal = yTickValues[0] * yValScale;
    }

    TextPainter(
        text: TextSpan(text: 'Scale: x$yValScale', style: textStyle),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, const Offset(15, 25));

    for (var i = 0; i < totalYLines; i++) {
      final yVal = yTickValues[i] * yValScale;
      final yPixel = i * yPixelStep;

      final textPainter = TextPainter(
        text: TextSpan(text: '${yVal.toInt()}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(4, yPixel - (textPainter.height / 2)));
    }

    final totalXLines = xTickValues.length;
    final xPixelStep = size.width / (totalXLines - 1);

    for (var i = 0; i < totalXLines; i++) {
      final xVal = xTickValues[i];
      final xPixel = i * xPixelStep;

      final textPainter = TextPainter(
        text: TextSpan(text: '${xVal.toInt()}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      var targetX = xPixel - (textPainter.width / 2);
      if (i == 0) {
        targetX = 4.0;
      } else if (i == totalXLines - 1) {
        targetX = size.width - textPainter.width - 4.0;
      }

      textPainter.paint(
        canvas,
        Offset(
          targetX,
          size.height - textPainter.height - 4.0,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LivePlotPainter oldDelegate) {
    return oldDelegate.vertexBuffers != vertexBuffers ||
        oldDelegate.eventXCoordinates != eventXCoordinates ||
        oldDelegate.gridLines != gridLines ||
        oldDelegate.xTickValues != xTickValues ||
        oldDelegate.yTickValues != yTickValues;
  }
}

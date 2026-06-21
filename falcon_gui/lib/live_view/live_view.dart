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
                  StreamParamSliders(streamAddress: streamAddress),
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
                              unifiedVertexBuffer: optimizedData,
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
    required this.unifiedVertexBuffer,
  });

  final Float32List unifiedVertexBuffer;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 52, 188, 251)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    canvas.drawRawPoints(PointMode.lines, unifiedVertexBuffer, paint);
  }

  @override
  bool shouldRepaint(covariant _LivePlotPainter oldDelegate) {
    return oldDelegate.unifiedVertexBuffer != unifiedVertexBuffer;
  }
}

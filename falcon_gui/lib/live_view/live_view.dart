import 'package:falcon_gui/live_view/connecting_view.dart';
import 'package:falcon_gui/live_view/live_plot_painter.dart';
import 'package:falcon_gui/live_view/live_view_controller.dart';
import 'package:falcon_gui/live_view/value_sliders.dart';
import 'package:flutter/material.dart';

class LiveView extends StatefulWidget {
  const LiveView({super.key});

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveViewController,
      builder: (context, _) {
        if (!liveViewController.isConnected) {
          return const Scaffold(
            body: LiveViewConnectingView(
              message: 'Connecting to WebSocket server...',
            ),
          );
        }

        final renderBuffers = liveViewController.optimizedRenderBuffers;
        if (renderBuffers.isEmpty) {
          return const Scaffold(
            body: LiveViewConnectingView(
              message: 'Connected. Waiting for stream data...',
            ),
          );
        }

        return Stack(
          children: [
            Column(
              children: renderBuffers.keys.map((address) {
                return Expanded(
                  child: _SignalCard(address: address),
                );
              }).toList(),
            ),
            const Positioned(
              left: 16,
              bottom: 16,
              child: ValueSliders(),
            ),
          ],
        );
      },
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    final optimizedData = liveViewController.optimizedRenderBuffers[address];
    final headIndex = liveViewController.renderBufferHeadIndices[address] ?? 0;

    final totalPixelCols = liveViewController.lastKnownScreenWidth.floor();
    final channels = (optimizedData != null && totalPixelCols > 0)
        ? (optimizedData.length ~/ (totalPixelCols * 4)).clamp(1, 64)
        : 1;

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
                address,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  liveViewController.lastKnownScreenWidth =
                      constraints.maxWidth;

                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: LivePlotPainter(
                        optimizedVertexBuffer: optimizedData,
                        channels: channels,
                        currentHeadIndex: headIndex,
                        visibleSamples: liveViewController.visibleSamples,
                        yScaleMultiplier: liveViewController.yScaleMultiplier,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

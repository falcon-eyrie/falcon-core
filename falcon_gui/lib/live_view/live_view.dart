import 'package:falcon_gui/live_view/connecting_view.dart';
import 'package:falcon_gui/live_view/falcon_websocket_controller.dart';
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
      listenable: Listenable.merge([falconWSController, liveViewController]),
      builder: (context, _) {
        final activeBuffers = liveViewController.realtimeSignalBuffers;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: !falconWSController.isConnected
                    ? LiveViewConnectingView(
                        message: 'Connecting to ${falconWSController.address}',
                      )
                    : activeBuffers.isEmpty
                    ? LiveViewConnectingView(
                        message:
                            'Connected to ${falconWSController.address}. Waiting for signal.',
                      )
                    : ListView.builder(
                        itemCount: activeBuffers.length,
                        itemBuilder: (context, index) {
                          final address = activeBuffers.keys.elementAt(index);
                          final buffer = activeBuffers[address]!;

                          return SizedBox(
                            height: 250,
                            child: Card(
                              margin: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      address,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: LivePlotPainter(
                                          signalBuffer: buffer,

                                          yScaleMultiplier: liveViewController
                                              .yScaleMultiplier,
                                          visibleSamples:
                                              liveViewController.visibleSamples,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const Positioned(left: 16, bottom: 16, child: ValueSliders()),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;

import 'package:falcon_gui/live_view/falcon_websocket_controller.dart';
import 'package:falcon_gui/live_view/live_view_controller.dart';
import 'package:falcon_gui/utils/debounce.dart';
import 'package:flutter/gestures.dart'; // Required for PointerScrollEvent tracking
import 'package:flutter/material.dart';

class ValueSliders extends StatefulWidget {
  const ValueSliders({super.key});

  @override
  State<ValueSliders> createState() => _ValueSlidersState();
}

class _ValueSlidersState extends State<ValueSliders> {
  final _scaleDebouncer = Debounce(delay: const Duration(milliseconds: 350));
  final _samplesDebouncer = Debounce(delay: const Duration(milliseconds: 350));

  late double _localLogScale;
  late int _localVisibleSamples;

  @override
  void initState() {
    super.initState();
    _localLogScale = math.log(liveViewController.yScaleMultiplier) / math.ln10;
    _localVisibleSamples = liveViewController.visibleSamples;
  }

  @override
  void dispose() {
    _scaleDebouncer.dispose();
    _samplesDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([falconWSController, liveViewController]),
      builder: (context, _) {
        final actualLogScale =
            math.log(liveViewController.yScaleMultiplier) / math.ln10;
        if ((_localLogScale - actualLogScale).abs() > 0.01 &&
            _scaleDebouncer.timer?.isActive != true) {
          _localLogScale = actualLogScale;
        }
        if (_localVisibleSamples != liveViewController.visibleSamples &&
            _samplesDebouncer.timer?.isActive != true) {
          _localVisibleSamples = liveViewController.visibleSamples;
        }

        final calculatedScale = math.pow(10, _localLogScale).toDouble();
        final scaleLabel = calculatedScale >= 1.0
            ? '${calculatedScale.toStringAsFixed(0)}x'
            : calculatedScale.toStringAsFixed(4);

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wrap track with a Listener block to intercept desktop mouse wheels
                Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      // Positive scroll delta means rolling downwards (reduce scale)
                      final double step = pointerSignal.scrollDelta.dy > 0
                          ? -0.05
                          : 0.05;
                      final double nextValue = (_localLogScale + step).clamp(
                        -6.0,
                        6.0,
                      );

                      setState(() => _localLogScale = nextValue);
                      _scaleDebouncer(() {
                        liveViewController.yScaleMultiplier = math
                            .pow(10, nextValue)
                            .toDouble();
                      });
                    }
                  },
                  child: _LeanSliderLayout(
                    label: 'SCALE',
                    valueLabel: scaleLabel,
                    color: Colors.greenAccent,
                    slider: Slider(
                      value: _localLogScale.clamp(-6.0, 6.0),
                      min: -6,
                      max: 6,
                      divisions: 500,
                      onChanged: (value) {
                        setState(() => _localLogScale = value);
                        _scaleDebouncer(() {
                          liveViewController.yScaleMultiplier = math
                              .pow(10, value)
                              .toDouble();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      // Scrolling down increases view bounds, scrolling up zooms in
                      final int step = pointerSignal.scrollDelta.dy > 0
                          ? -500
                          : 500;
                      final int nextValue = (_localVisibleSamples + step).clamp(
                        100,
                        kAllocatedSampleBufferSize,
                      );

                      setState(() => _localVisibleSamples = nextValue);
                      _samplesDebouncer(() {
                        liveViewController.visibleSamples = nextValue;
                      });
                    }
                  },
                  child: _LeanSliderLayout(
                    label: 'SAMPLES',
                    valueLabel: '$_localVisibleSamples',
                    color: Colors.cyanAccent,
                    slider: Slider(
                      value: _localVisibleSamples.toDouble(),
                      min: 100,
                      max: kAllocatedSampleBufferSize.toDouble(),
                      divisions: 1000,
                      onChanged: (value) {
                        final intIntSamples = value.toInt();
                        setState(() => _localVisibleSamples = intIntSamples);
                        _samplesDebouncer(() {
                          liveViewController.visibleSamples = intIntSamples;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeanSliderLayout extends StatelessWidget {
  const _LeanSliderLayout({
    required this.label,
    required this.valueLabel,
    required this.color,
    required this.slider,
  });

  final String label;
  final String valueLabel;
  final Color color;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valueLabel,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: color,
                inactiveTrackColor: Colors.white12,
                thumbColor: color,
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: slider,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

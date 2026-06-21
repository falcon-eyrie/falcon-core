import 'dart:math' as math;

import 'package:falcon_gui/live_view/live_view_controller.dart';
import 'package:falcon_gui/utils/debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ViewParamSliders extends StatefulWidget {
  const ViewParamSliders({super.key});

  @override
  State<ViewParamSliders> createState() => _ViewParamSlidersState();
}

class _ViewParamSlidersState extends State<ViewParamSliders> {
  final _samplesDebouncer = Debounce(delay: const Duration(milliseconds: 50));
  late int _localVisibleSamples;

  @override
  void initState() {
    super.initState();
    // Default or current baseline window source state fallback
    _localVisibleSamples = liveViewController.visibleSamples;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveViewController,
      builder: (context, _) {
        final actualSamples = liveViewController.visibleSamples;
        if (_localVisibleSamples != actualSamples &&
            _samplesDebouncer.timer?.isActive != true) {
          _localVisibleSamples = actualSamples;
        }

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // Incremental scroll updates
                  final step = pointerSignal.scrollDelta.dy > 0 ? -1000 : 1000;
                  final nextValue = (_localVisibleSamples + step).clamp(
                    1,
                    1024 * 1024,
                  );

                  setState(() => _localVisibleSamples = nextValue);
                  _samplesDebouncer(() {
                    liveViewController.updateVisibleSamples(nextValue);
                  });
                }
              },
              child: _LeanSliderLayout(
                label: 'WINDOW',
                valueLabel: '$_localVisibleSamples',
                color: Colors.cyanAccent,
                slider: Slider(
                  value: _localVisibleSamples.toDouble(),
                  min: 1,
                  max: (1024 * 1024).toDouble(),
                  divisions: 1000,
                  onChanged: (value) {
                    final nextValue = value.toInt();
                    setState(() => _localVisibleSamples = nextValue);
                    _samplesDebouncer(() {
                      liveViewController.updateVisibleSamples(nextValue);
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StreamParamSliders extends StatefulWidget {
  const StreamParamSliders({required this.streamAddress, super.key});

  final String streamAddress;

  @override
  State<StreamParamSliders> createState() => _StreamParamSlidersState();
}

class _StreamParamSlidersState extends State<StreamParamSliders> {
  final _scaleDebouncer = Debounce(delay: const Duration(milliseconds: 50));
  late double _localLogScale;

  @override
  void initState() {
    super.initState();
    final initialScale = liveViewController.getScaleMultiplier(
      widget.streamAddress,
    );
    _localLogScale = math.log(initialScale) / math.ln10;
  }

  @override
  void dispose() {
    _scaleDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: liveViewController,
      builder: (context, _) {
        final actualScale = liveViewController.getScaleMultiplier(
          widget.streamAddress,
        );
        final actualLogScale = math.log(actualScale) / math.ln10;

        if ((_localLogScale - actualLogScale).abs() > 0.01 &&
            _scaleDebouncer.timer?.isActive != true) {
          _localLogScale = actualLogScale;
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
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  final step = pointerSignal.scrollDelta.dy > 0 ? -0.05 : 0.05;
                  final nextValue = (_localLogScale + step).clamp(-10.0, 10.0);

                  setState(() => _localLogScale = nextValue);
                  _scaleDebouncer(() {
                    liveViewController.updateProcessorScale(
                      widget.streamAddress,
                      math.pow(10, nextValue).toDouble(),
                    );
                  });
                }
              },
              child: _LeanSliderLayout(
                label: 'SCALE',
                valueLabel: scaleLabel,
                color: Colors.greenAccent,
                slider: Slider(
                  value: _localLogScale.clamp(-10.0, 10.0),
                  min: -10,
                  max: 10,
                  divisions: 500,
                  onChanged: (value) {
                    setState(() => _localLogScale = value);
                    _scaleDebouncer(() {
                      liveViewController.updateProcessorScale(
                        widget.streamAddress,
                        math.pow(10, value).toDouble(),
                      );
                    });
                  },
                ),
              ),
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
      width: 40,
      height: 120,
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

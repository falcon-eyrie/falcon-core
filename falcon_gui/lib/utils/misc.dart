import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:flutter/material.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

final topLeftMatrix = Matrix4.identity()
  ..translateByDouble(
    40,
    40,
    0,
    1,
  );

const greyScaleFilter = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class MultiListener extends StatelessWidget {
  const MultiListener({required this.builder, super.key});
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphManager,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: falconManager,
          builder: (context, _) {
            return builder(context);
          },
        );
      },
    );
  }
}

extension CapitalizeX on String {
  String get capitalized {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

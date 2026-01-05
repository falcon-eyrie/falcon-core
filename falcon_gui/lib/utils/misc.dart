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

import 'package:flutter/material.dart';

extension ThemeExtensions on BuildContext {
  ThemeData get t => Theme.of(this);
  ColorScheme get c => Theme.of(this).colorScheme;
}

class FalconTheme {
  const FalconTheme(this.textTheme);
  final TextTheme textTheme;

  ThemeData light() {
    return _theme(lightScheme());
  }

  ThemeData dark() {
    return _theme(darkScheme());
  }

  ThemeData _theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00341a),
      surfaceTint: Color(0xff2d6a44),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff145431),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1d3023),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff3a4e3f),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff00313b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff244f59),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff6fbf3),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff262e28),
      outlineVariant: Color(0xff434b44),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322d),
      inversePrimary: Color(0xff95d5a7),
      primaryFixed: Color(0xff145431),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003b1e),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff3a4e3f),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff243729),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff244f59),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff053842),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb5bab3),
      surfaceBright: Color(0xfff6fbf3),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffedf2eb),
      surfaceContainer: Color(0xffdfe4dd),
      surfaceContainerHigh: Color(0xffd1d6cf),
      surfaceContainerHighest: Color(0xffc3c8c1),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbeffcf),
      surfaceTint: Color(0xff95d5a7),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff92d1a3),
      onPrimaryContainer: Color(0xff000f05),
      secondary: Color(0xffdff6e1),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffb2c8b5),
      onSecondaryContainer: Color(0xff000f05),
      tertiary: Color(0xffd6f5ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff9fcad6),
      onTertiaryContainer: Color(0xff000d12),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff101510),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffeaf2e8),
      outlineVariant: Color(0xffbdc5bb),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdfe4dd),
      inversePrimary: Color(0xff12522f),
      primaryFixed: Color(0xffb1f1c2),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff95d5a7),
      onPrimaryFixedVariant: Color(0xff001507),
      secondaryFixed: Color(0xffd2e8d4),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb6ccb9),
      onSecondaryFixedVariant: Color(0xff031509),
      tertiaryFixed: Color(0xffbeeaf7),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffa2cdda),
      onTertiaryFixedVariant: Color(0xff001419),
      surfaceDim: Color(0xff101510),
      surfaceBright: Color(0xff4c514c),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1c211c),
      surfaceContainer: Color(0xff2c322d),
      surfaceContainerHigh: Color(0xff373d38),
      surfaceContainerHighest: Color(0xff434843),
    );
  }
}

abstract final class DefaultProcessorColor {
  static Color? byClassName({required String className}) {
    return {
      'SourceProcessor': const Color.fromARGB(255, 183, 67, 59),
      'FilterProcessor': const Color.fromARGB(255, 57, 68, 129),
      'SinkProcessor': const Color.fromARGB(255, 92, 72, 138),
      'DistruptorProcessor': const Color.fromARGB(255, 173, 59, 183),
    }[className];
  }
}

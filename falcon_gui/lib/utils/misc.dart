import 'dart:io';

import 'package:flutter/material.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

Directory get ubuntuHomePath {
  return Directory(Platform.environment['HOME'] ?? '').absolute;
}

Directory get falconInstallationPath {
  return Directory(
    '${ubuntuHomePath.path}/.local/share/org.falcon-eyrie.falcon_gui/',
  )..createSync(recursive: true);
}

Directory get defaultGraphsDirectory =>
    Directory('${ubuntuHomePath.path}/falcon/resources/graphs')
      ..createSync(recursive: true);

// TODO(ben): this regex is not matching the falcon backend one, fix it
final processorIdRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

final processorIdSuffixRegex = RegExp(r'(\d+)$');

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

extension CapitalizeX on String {
  String get capitalized {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class ClickableIcon extends StatelessWidget {
  const ClickableIcon({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });
  final Icon icon;
  final VoidCallback onPressed;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: tooltip == null
            ? icon
            : Tooltip(
                message: tooltip,
                child: icon,
              ),
      ),
    );
  }
}

String getAbsolutePathForUbuntu(String input) {
  var path = input.replaceAll(r'$HOME', ubuntuHomePath.path);

  if (path.startsWith('~')) {
    path = path.replaceFirst('~', ubuntuHomePath.path);
  }

  return Directory(path).absolute.path;
}

ThemeMode themeModeFromString(String mode) {
  switch (mode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

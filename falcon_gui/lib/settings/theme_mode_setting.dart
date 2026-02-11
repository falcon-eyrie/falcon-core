import 'dart:async';

import 'package:falcon_gui/utils/local_config.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/material.dart';

Future<void> _saveThemeModeToLocalConfig(ThemeMode mode) async {
  final modeName = switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
  await LocalConfigManager.setThemeMode(modeName);
}

class ThemeModeSetting extends StatelessWidget {
  const ThemeModeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    // use CupertinoSegmentedControl to show 3 options: light, dark, system
    return ValueListenableBuilder<LocalConfig>(
      valueListenable: localConfigNotifier,
      builder: (context, localConfig, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theme Mode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Light'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('System'),
                  ),
                ],
                selected: <ThemeMode>{
                  themeModeFromString(localConfig.themeMode),
                },
                onSelectionChanged: (newSelection) {
                  final newMode = newSelection.first;
                  unawaited(_saveThemeModeToLocalConfig(newMode));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> loadThemeModeFromSharedPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    themeNotifier.value = ThemeMode.values[themeIndex];
  } catch (_) {}
}

Future<void> saveThemeModeToSharedPreferences(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('theme_mode', mode.index);
}

class ThemeModeSetting extends StatelessWidget {
  const ThemeModeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    // use CupertinoSegmentedControl to show 3 options: light, dark, system
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return Column(
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
              selected: <ThemeMode>{mode},
              onSelectionChanged: (newSelection) {
                final newMode = newSelection.first;
                themeNotifier.value = newMode;
                unawaited(saveThemeModeToSharedPreferences(newMode));
              },
            ),
          ],
        );
      },
    );
  }
}

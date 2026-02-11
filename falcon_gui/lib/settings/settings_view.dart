import 'package:falcon_gui/dialogs/dialog_view.dart';
import 'package:falcon_gui/settings/local_backend_settings.dart';
import 'package:falcon_gui/settings/theme_mode_setting.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DialogView(
      title: 'Settings',
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalBackendSettings(),
            SizedBox(height: 12),
            ThemeModeSetting(),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

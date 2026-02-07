import 'package:falcon_gui/dialogs/dialog_view.dart';
import 'package:falcon_gui/settings/theme_mode_setting.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const DialogView(
      title: 'Settings',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FalconProcessPriorityStatus(),
          // SizedBox(height: 12),
          ThemeModeSetting(),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}

import 'package:falcon_gui/settings/falcon_priority_status.dart';
import 'package:falcon_gui/utils/dialog_view.dart';
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
          FalconProcessPriorityStatus(),
        ],
      ),
    );
  }
}

// TODO(ben): a setting to change config.yaml 

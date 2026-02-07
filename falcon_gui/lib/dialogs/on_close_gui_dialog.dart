import 'dart:async';

import 'package:falcon_gui/dialogs/dialog_view.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

Future<void> showOnCloseGUIDialog() async {
  if (falconManager.localFalconBackendPid == null) {
    return;
  }

  await showDialog<void>(
    context: globalNavigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) {
      return DialogView(
        title: 'Close Falcon GUI',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Remix.close_circle_line,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Do you want to keep the Falcon backend processes '
              'running in the background or kill it?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await falconManager.killFalcon();
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  child: const Text('Kill Processes'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await falconManager.dispose();
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  child: const Text('Leave Running'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

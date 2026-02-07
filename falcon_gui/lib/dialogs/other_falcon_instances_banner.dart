import 'dart:async';

import 'package:falcon_gui/dialogs/dialog_view.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

Future<void> showFalconInstancesNotFoundBanner() async {
  await showDialog<void>(
    context: globalNavigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) {
      return DialogView(
        title: 'Falcon Backend',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Remix.information_line,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Falcon backend instances were detected running on '
              'this machine.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Would you like to create a new instance in this machine '
              'or connect to a remote instance?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(falconManager.initLocalBackend());
                  },
                  child: const Text('Create New Instance In This Machine'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO(ben): implement remote connection flow
                    Navigator.of(context).pop();
                  },
                  child: const Text('Connect to Remote Instance'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

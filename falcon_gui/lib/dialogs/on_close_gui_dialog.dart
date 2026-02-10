import 'dart:async';

import 'package:falcon_gui/dialogs/dialog_view.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

Future<bool?> showOnCloseGUIDialog() async {
  return showDialog<bool>(
    context: globalNavigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) {
      return DialogView(
        title: 'Close Falcon GUI',
        showCloseButton: false,
        content: SizedBox(
          width: 600,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Remix.alarm_warning_line,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'A Falcon backend instance is currently running '
                  'on this machine.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  _closeDialogExplanation,
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Kill Backend and Exit'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Leave It Running and Exit'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

const String _closeDialogExplanation =
    'You can choose to kill the backend, which will '
    'stop the running graph and processors, or leave '
    'it running in the background. If you choose to '
    'leave it running, you can reopen the Falcon GUI '
    'any time to take control of it. Please be aware that unless '
    'you explicitly kill it, it will continue running '
    'forever in the background.\n\n'
    'When running a graph with low latency requirements, '
    "it's generally recommended to close the GUI to free "
    'up system resources and ensure optimal performance for '
    'the backend.';

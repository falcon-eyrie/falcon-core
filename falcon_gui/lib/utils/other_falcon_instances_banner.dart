import 'dart:async';

import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

void showOtherFalconInstancesBanner({required List<int> pids}) {
  unawaited(
    showDialog<void>(
      context: globalNavigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    RemixIcons.error_warning_line,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Other Falcon Instances Detected',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Only one Falcon instance can run at a time. '
                    'Falcon GUI needs to create its own instance to proceed. '
                    'Please terminate the existing instances before '
                    'continuing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Running PIDs:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pids.map(
                          (pid) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              pid.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can also use the "Send Terminate Signal" button below '
                    'to request termination from those instances.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      unawaited(falconManager.killOthersAndSpawnNew());
                      Navigator.of(context).pop();
                    },
                    child: const Text('Send Terminate Signal'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

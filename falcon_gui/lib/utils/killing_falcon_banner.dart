import 'dart:async';

import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/material.dart';

void showKillingFalconBanner() {
  // This is just to show a non-dismissible dialog while killing Falcon.
  // Don't wait for the dialog to close, because it will never be closed.

  unawaited(
    showDialog<void>(
      context: globalNavigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'Stopping Falcon instance...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

import 'dart:async';

import 'package:falcon_gui/dialogs/dialog_view.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

enum StatusDialogType {
  info,
  warning,
  error,
}

void showStatusDialog({
  required String title,
  required String message,
  required StatusDialogType type,
}) {
  unawaited(
    showDialog<void>(
      context: globalNavigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return DialogView(
          title: title,
          content: Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.c.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    ),
  );
}

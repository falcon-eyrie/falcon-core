import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class DialogView extends StatelessWidget {
  const DialogView({
    required this.title,
    required this.content,
    super.key,
    this.onClose,
  });
  final String title;
  final Widget content;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Center(
            child: Column(
              children: [
                ColoredBox(
                  color: context.c.surfaceContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(RemixIcons.close_line),
                        onPressed: onClose ?? () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

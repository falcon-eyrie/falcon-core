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
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Center(
            child: Column(
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.c.surfaceContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(RemixIcons.close_line),
                        onPressed: onClose ?? () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
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

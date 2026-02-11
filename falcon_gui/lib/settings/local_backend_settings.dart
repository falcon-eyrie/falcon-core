import 'package:falcon_gui/utils/file_picker.dart';
import 'package:falcon_gui/utils/local_config.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

enum _PathConfigType { resources, output, logs }

class LocalBackendSettings extends StatelessWidget {
  const LocalBackendSettings({super.key});

  Future<void> _onPathSelect(_PathConfigType type) async {
    switch (type) {
      case _PathConfigType.resources:
        final result = await FalconFilePicker.pickDirectory(
          initialDirectory:
              localConfigNotifier.value.serverSideStorageResources,
          dialogTitle: 'Select Resources Directory',
        );

        if (result != null) {
          await LocalConfigManager.setServerSideStorageResources(result.path);
        }
      case _PathConfigType.output:
        final result = await FalconFilePicker.pickDirectory(
          initialDirectory:
              localConfigNotifier.value.serverSideStorageEnvironment,
          dialogTitle: 'Select Output Directory',
        );

        if (result != null) {
          await LocalConfigManager.setServerSideStorageEnvironment(result.path);
        }
      case _PathConfigType.logs:
        final result = await FalconFilePicker.pickDirectory(
          initialDirectory: localConfigNotifier.value.loggingPath,
          dialogTitle: 'Select Logs Directory',
        );

        if (result != null) {
          await LocalConfigManager.setLoggingPath(result.path);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: localConfigNotifier,
      builder: (context, localConfig, _) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local Backend Configuration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Changes will take effect after restarting the local backend.',
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.c.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.c.outlineVariant),
                ),
                padding: const EdgeInsets.all(8),
                width: 600,

                child: Column(
                  children: [
                    _PathSettingRow(
                      label: 'Resources',
                      path: localConfig.serverSideStorageResources,
                      onSelect: () => _onPathSelect(_PathConfigType.resources),
                    ),
                    const SizedBox(height: 16),
                    _PathSettingRow(
                      label: 'Output',
                      path: localConfig.serverSideStorageEnvironment,
                      onSelect: () => _onPathSelect(_PathConfigType.output),
                    ),
                    const SizedBox(height: 16),
                    _PathSettingRow(
                      label: 'Logs',
                      path: localConfig.loggingPath,
                      onSelect: () => _onPathSelect(_PathConfigType.logs),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PathSettingRow extends StatelessWidget {
  const _PathSettingRow({
    required this.label,
    required this.path,
    required this.onSelect,
  });

  final String label;
  final String path;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.c.onSurfaceVariant,
          ),
        ),

        Row(
          children: [
            Expanded(
              child: Text(
                path,
                style: TextStyle(
                  fontSize: 14,
                  color: context.c.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(RemixIcons.folder_2_line),
              onPressed: onSelect,
            ),
          ],
        ),
      ],
    );
  }
}

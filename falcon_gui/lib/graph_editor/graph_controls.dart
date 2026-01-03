import 'package:falcon_gui/settings/settings_view.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class GraphToolbar extends StatelessWidget {
  const GraphToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.c.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const SettingsView(),
                );
              },
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () async {
                await falconManager.sendTestCommandSimple();
              },
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                debugPrint('Reset pressed');
              },
              child: const Text('Reset'),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: () {
                debugPrint('Undo pressed');
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: () {
                debugPrint('Redo pressed');
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.zoom_in_map),
              tooltip: 'Reset zoom',
              onPressed: graphManager.resetZoom,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom out',
              onPressed: graphManager.zoomOut,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom in',
              onPressed: graphManager.zoomIn,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Run Pipeline',
              onPressed: () {
                debugPrint('Play pressed');
              },
            ),
          ],
        ),
      ),
    );
  }
}

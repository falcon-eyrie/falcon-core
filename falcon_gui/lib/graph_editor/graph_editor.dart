import 'package:falcon_gui/graph_editor/editor_view.dart';
import 'package:falcon_gui/graph_editor/processors_panel.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:flutter/material.dart';

class GraphEditor extends StatelessWidget {
  const GraphEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Control Panel Row
        _EditorControls(),
        // Main Editor Row
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: ProcessorsPanel(),
              ),
              Expanded(child: EditorView()),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorControls extends StatelessWidget {
  const _EditorControls();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              debugPrint('Settings pressed');
            },
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              debugPrint('Save pressed');
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

          // You can add more controls here, e.g., zoom, settings, etc.
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
    );
  }
}

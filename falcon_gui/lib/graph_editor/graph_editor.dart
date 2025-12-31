import 'package:falcon_gui/graph_editor/editor_view.dart';
import 'package:falcon_gui/graph_editor/processors_panel.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
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

              _YamlEditor(),
            ],
          ),
        ),
      ],
    );
  }
}

class _YamlEditor extends StatefulWidget {
  const _YamlEditor();

  @override
  State<_YamlEditor> createState() => _YamlEditorState();
}

class _YamlEditorState extends State<_YamlEditor> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphManager,
      builder: (context, _) {
        if (controller.text != graphManager.graphAsYaml) {
          controller.value = TextEditingValue(
            text: graphManager.graphAsYaml,
            selection: controller.selection,
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 300,
            height: double.infinity,
            child: TextFormField(
              controller: controller,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                labelText: 'Graph YAML',
                border: OutlineInputBorder(),
                errorMaxLines: 10,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textAlignVertical: TextAlignVertical.top,
              validator: (value) {
                try {
                  FalconGraphSerializerX.fromYaml(value ?? '');
                  return null;
                } on FalconGraphYamlParserException catch (e) {
                  return e.message;
                  // ignore: avoid_catches_without_on_clauses
                } catch (e) {
                  return '$e';
                }
              },
              onChanged: (value) {
                try {
                  graphManager.loadGraph(
                    FalconGraphSerializerX.fromYaml(value),
                  );
                  // ignore: avoid_catches_without_on_clauses
                } catch (_) {}
              },
            ),
          ),
        );
      },
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

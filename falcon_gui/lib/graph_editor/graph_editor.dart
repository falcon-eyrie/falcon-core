import 'package:falcon_gui/graph_editor/editor_view.dart';
import 'package:falcon_gui/graph_editor/processors_panel.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:flutter/material.dart';

class GraphEditor extends StatefulWidget {
  const GraphEditor({super.key});

  @override
  State<GraphEditor> createState() => _GraphEditorState();
}

class _GraphEditorState extends State<GraphEditor> {
  bool _isProcessorsCollapsed = false;
  bool _isYamlCollapsed = true;
  final double _processorsWidth = 300;
  final double _yamlWidth = 400;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _EditorControls(),
        Expanded(
          child: Row(
            children: [
              // Processors Panel
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isProcessorsCollapsed ? 40 : _processorsWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isProcessorsCollapsed
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                      ),
                      onPressed: () {
                        setState(() {
                          _isProcessorsCollapsed = !_isProcessorsCollapsed;
                        });
                      },
                    ),
                    Expanded(
                      child: _isProcessorsCollapsed
                          ? const SizedBox.shrink()
                          : const ProcessorsPanel(),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 1),

              // Editor View
              const Expanded(child: EditorView()),

              const VerticalDivider(width: 1),

              // YAML Editor
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isYamlCollapsed ? 40 : _yamlWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    IconButton(
                      icon: Icon(
                        _isYamlCollapsed
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                      ),
                      onPressed: () {
                        setState(() {
                          _isYamlCollapsed = !_isYamlCollapsed;
                        });
                      },
                    ),
                    Expanded(
                      child: _isYamlCollapsed
                          ? const SizedBox.shrink()
                          : const _YamlEditor(),
                    ),
                  ],
                ),
              ),
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
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: graphManager.graphAsYaml);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphManager,
      builder: (context, _) {
        final currentYaml = graphManager.graphAsYaml;
        if (controller.text != currentYaml) {
          controller.text = currentYaml;
        }
        return Padding(
          padding: const EdgeInsets.all(8),
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
              } catch (e) {
                return '$e';
              }
            },
            onChanged: (value) {
              try {
                graphManager.loadGraph(
                  FalconGraphSerializerX.fromYaml(value),
                );
              } catch (_) {}
            },
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

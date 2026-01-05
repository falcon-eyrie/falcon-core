import 'package:falcon_gui/graph_editor/editor_view.dart';
import 'package:falcon_gui/graph_editor/graph_controls.dart';
import 'package:falcon_gui/graph_editor/processors_panel.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class GraphEditor extends StatefulWidget {
  const GraphEditor({super.key});

  @override
  State<GraphEditor> createState() => _GraphEditorState();
}

class _GraphEditorState extends State<GraphEditor> {
  bool _isProcessorsCollapsed = false;
  bool _isYamlCollapsed = true;
  final double _processorsWidth = 400;
  final double _yamlWidth = 400;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GraphToolbar(),
        Expanded(
          child: Stack(
            children: [
              Row(
                children: [
                  // Processors Panel (left)
                  if (!_isProcessorsCollapsed)
                    SizedBox(
                      width: _processorsWidth,
                      child: ColoredBox(
                        color: context.c.surfaceContainer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _isProcessorsCollapsed = true;
                                });
                              },
                            ),
                            const Expanded(
                              child: ProcessorsPanel(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Expanded(
                    child: EditorView(),
                  ),

                  // YAML Editor (right)
                  if (!_isYamlCollapsed)
                    SizedBox(
                      width: _yamlWidth,
                      child: ColoredBox(
                        color: context.c.surfaceContainer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _isYamlCollapsed = true;
                                });
                              },
                            ),
                            const Expanded(
                              child: _YamlEditor(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (_isProcessorsCollapsed)
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.widgets),
                    tooltip: 'Show Processors',
                    onPressed: () {
                      setState(() {
                        _isProcessorsCollapsed = false;
                      });
                    },
                  ),
                ),
              if (_isYamlCollapsed)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.code),
                    tooltip: 'Show YAML',
                    onPressed: () {
                      setState(() {
                        _isYamlCollapsed = false;
                      });
                    },
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
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: graphManager.graphAsYaml);
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphManager,
      builder: (context, _) {
        final currentYaml = graphManager.graphAsYaml;
        // Only update if not focused and text differs
        if (!focusNode.hasFocus && controller.text != currentYaml) {
          controller.text = currentYaml;
        }
        return Padding(
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
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

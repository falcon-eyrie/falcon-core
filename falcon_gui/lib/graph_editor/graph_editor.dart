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

  void _onYamlCollapseToggled() {
    setState(() {
      _isYamlCollapsed = !_isYamlCollapsed;
    });
  }

  void _onProcessorPanelCollapseToggled() {
    setState(() {
      _isProcessorsCollapsed = !_isProcessorsCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GraphToolbar(
          isProcessorsCollapsed: _isProcessorsCollapsed,
          isYamlCollapsed: _isYamlCollapsed,
          onProcessorPanelClicked: _onProcessorPanelCollapseToggled,
          onYamlPanelClicked: _onYamlCollapseToggled,
        ),
        Expanded(
          child: Stack(
            children: [
              Row(
                children: [
                  // Processors Panel (left)
                  if (!_isProcessorsCollapsed) ...[
                    const ProcessorsPanel(),
                  ],

                  const Expanded(
                    child: EditorView(),
                  ),

                  // YAML Editor (right)
                  if (!_isYamlCollapsed) ...[
                    const _YamlEditor(),
                  ],
                ],
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
    focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus) {
      final currentYaml = graphManager.graphAsYaml;
      if (controller.text != currentYaml) {
        controller.text = currentYaml;
      }
    }
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
        return Container(
          width: 450,
          padding: const EdgeInsets.all(8),
          color: context.c.surfaceContainer,
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

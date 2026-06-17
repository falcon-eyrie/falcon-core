import 'dart:async';

import 'package:falcon_gui/graph_editor/controls_bar.dart';
import 'package:falcon_gui/graph_editor/editor_view.dart';
import 'package:falcon_gui/graph_editor/logs_panel.dart';
import 'package:falcon_gui/graph_editor/processors_panel.dart';
import 'package:falcon_gui/graph_editor/status_bar.dart';
import 'package:falcon_gui/live_view/live_view.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/debounce.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class GraphEditor extends StatefulWidget {
  const GraphEditor({super.key});

  @override
  State<GraphEditor> createState() => _GraphEditorState();
}

class _GraphEditorState extends State<GraphEditor> {
  ActiveProcessorCategory? _activeCategory;
  bool _isYamlCollapsed = true;
  bool _isLogsCollapsed = false;
  bool _showLiveView = false;

  Timer? _hideProcessorPanelTimer;

  void _setActiveProcessorPanelCategory(ActiveProcessorCategory? category) {
    if (_showLiveView) {
      return;
    }
    if (category == null) {
      _hideProcessorPanelTimer = Timer(Duration.zero, () {
        setState(() => _activeCategory = null);
      });
    } else {
      setState(() => _activeCategory = category);
    }
  }

  void _onYamlCollapseToggled() {
    setState(() {
      _isYamlCollapsed = !_isYamlCollapsed;
    });
  }

  void _onLogsCollapseToggled() {
    setState(() {
      _isLogsCollapsed = !_isLogsCollapsed;
    });
  }

  void _onLiveViewToggled() {
    setState(() {
      _showLiveView = !_showLiveView;
      _isYamlCollapsed = true;
      _isLogsCollapsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          onExit: (_) => _setActiveProcessorPanelCategory(
            null,
          ),
          onHover: (_) => _hideProcessorPanelTimer?.cancel(),
          child: ControlsBar(
            activeCategory: _activeCategory,
            onProcessorCategoryHovered: _setActiveProcessorPanelCategory,
            onLiveViewToggled: _onLiveViewToggled,
          ),
        ),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          IndexedStack(
                            index: _showLiveView ? 1 : 0,
                            children: const [EditorView(), LiveView()],
                          ),
                          if (_activeCategory != null) ...[
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,

                              child: Center(
                                child: MouseRegion(
                                  onHover: (_) =>
                                      _hideProcessorPanelTimer?.cancel(),
                                  onExit: (_) =>
                                      _setActiveProcessorPanelCategory(null),
                                  child: ProcessorsPanel(
                                    activeCategory: _activeCategory!,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // YAML Editor (right)
                    if (!_isYamlCollapsed) ...[
                      const _YamlEditor(),
                    ],
                  ],
                ),
              ), // Logs Panel left
              if (!_isLogsCollapsed) ...[
                LogsPanel(onHidden: _onLogsCollapseToggled),
              ],
            ],
          ),
        ),

        StatusBar(
          isLogsCollapsed: _isLogsCollapsed,
          onLogsPanelClicked: _onLogsCollapseToggled,
          isYamlEditorCollapsed: _isYamlCollapsed,
          onYamlEditorClicked: _onYamlCollapseToggled,
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
  final Debounce _buildGraphDebounce = Debounce(
    delay: const Duration(milliseconds: 500),
  );
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
            enabled: falconManager.canEditGraph,
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              labelText: falconManager.currentGraphFileName,
              border: const OutlineInputBorder(),
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
                final newGraph = FalconGraphSerializerX.fromYaml(value);

                _buildGraphDebounce(() => graphManager.loadGraph(newGraph));
              } catch (_) {}
            },
          ),
        );
      },
    );
  }
}

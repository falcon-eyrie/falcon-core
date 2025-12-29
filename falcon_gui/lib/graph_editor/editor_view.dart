import 'package:falcon_gui/graph_editor/proessor_item.dart';
import 'package:falcon_gui/state/node_manager.dart';
import 'package:flutter/material.dart';

/// EditorView
///
/// Main canvas/editor view for Linux desktop. Users can pan,
/// zoom, and drag nodes.
/// Nodes are represented as NodeItem widgets with data stored
/// in NodeData objects.
/// This implementation prevents visual shifting of other nodes when nodes
/// are moved toward top or left of the canvas.
class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCanvas());
  }

  void _centerCanvas() {
    final viewportSize = MediaQuery.of(context).size;
    final canvasSize = graphManager.canvasSize;
    graphManager.transformationController.value = Matrix4.identity()
      ..translateByDouble(
        (viewportSize.width - canvasSize.width) / 2,
        (viewportSize.height - canvasSize.height) / 2,
        0,
        1,
      );
  }

  /// Converts global screen position to world coordinates
  Offset _toScene(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.globalToLocal(globalPosition) ?? Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphManager,
      builder: (context, _) {
        // 1. Convert nodes map to list and sort by lastModified
        final nodes = graphManager.processors.toList();

        return InteractiveViewer(
          transformationController: graphManager.transformationController,
          minScale: 0.2,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          child: SizedBox(
            height: graphManager.canvasSize.height,
            width: graphManager.canvasSize.width,
            child: Stack(
              clipBehavior: Clip.none,
              children: nodes.map((node) {
                return Positioned(
                  key: ValueKey(node.id),
                  left: node.uiMetadata.position.dx,
                  top: node.uiMetadata.position.dy,
                  child: GestureDetector(
                    onPanStart: (details) {
                      final scenePosition = _toScene(details.globalPosition);
                      graphManager.onNodeDragStart(
                        id: node.id,
                        scenePosition: scenePosition,
                      );
                    },
                    onPanUpdate: (details) {
                      final scenePosition = _toScene(details.globalPosition);
                      graphManager.onNodeDragUpdate(
                        id: node.id,
                        newPos: scenePosition,
                      );
                    },
                    onPanEnd: (_) => graphManager.onNodeDragEnd(id: node.id),
                    onTapDown: (_) => graphManager.onNodeClicked(id: node.id),
                    child: ProcessorItem(processor: node),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

import 'package:falcon_gui/node_item.dart';
import 'package:falcon_gui/node_manager.dart';
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
    final canvasSize = nodeManager.canvasSize;
    nodeManager.transformationController.value = Matrix4.identity()
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
      animation: nodeManager,
      builder: (context, _) {
        // 1. Convert nodes map to list and sort by lastModified
        final nodes = nodeManager.nodes.values.toList()
          ..sort(
            (a, b) =>
                a.lastModified?.compareTo(
                  b.lastModified ?? DateTime.now(),
                ) ??
                0,
          );

        return InteractiveViewer(
          transformationController: nodeManager.transformationController,
          minScale: 0.2,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          child: SizedBox(
            height: nodeManager.canvasSize.height,
            width: nodeManager.canvasSize.width,
            child: Stack(
              clipBehavior: Clip.none,
              children: nodes.map((node) {
                return Positioned(
                  key: ValueKey(node.id),
                  left: node.position.dx,
                  top: node.position.dy,
                  child: GestureDetector(
                    onPanStart: (details) {
                      final scenePosition = _toScene(details.globalPosition);
                      nodeManager.onNodeDragStart(
                        id: node.id,
                        scenePosition: scenePosition,
                      );
                    },
                    onPanUpdate: (details) {
                      final scenePosition = _toScene(details.globalPosition);
                      nodeManager.onNodeDragUpdate(
                        id: node.id,
                        newPos: scenePosition,
                      );
                    },
                    onPanEnd: (_) => nodeManager.onNodeDragEnd(id: node.id),
                    onTapDown: (_) => nodeManager.onNodeClicked(id: node.id),
                    child: NodeItem(node: node),
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

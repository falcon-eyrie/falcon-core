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
  final TransformationController _controller = TransformationController();
  Offset? grabOffset;

  /// Converts global screen position to world coordinates
  Offset _toScene(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final local = renderBox?.globalToLocal(globalPosition) ?? Offset.zero;
    return MatrixUtils.transformPoint(
      _controller.value.clone()..invert(),
      local,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: nodeManager,
      builder: (context, _) {
        // 1. Convert nodes map to list and sort by lastModified
        final nodes = nodeManager.nodes.values.toList()
          ..sort((a, b) => a.lastModified.compareTo(b.lastModified));

        return InteractiveViewer(
          transformationController: _controller,
          minScale: 0.2,
          maxScale: 10,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          child: ColoredBox(
            color: Colors.orange,
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
                        // Convert global touch to scene coordinates
                        final scenePos = _toScene(details.globalPosition);
                        grabOffset = scenePos - node.position;
                        nodeManager.focus(node.id);
                      },
                      onPanUpdate: (details) {
                        // Update node position relative to grab offset
                        final scenePos = _toScene(details.globalPosition);

                        nodeManager.updatePosition(
                          node.id,
                          scenePos - (grabOffset ?? Offset.zero),
                        );
                      },
                      onPanEnd: (_) => grabOffset = null,
                      onTapDown: (_) => nodeManager.focus(node.id),
                      child: NodeItem(node: node),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

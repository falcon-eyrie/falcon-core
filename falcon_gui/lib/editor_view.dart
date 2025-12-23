import 'package:falcon_gui/node_data.dart';
import 'package:falcon_gui/node_manager.dart';
import 'package:falcon_gui/node_item.dart';
import 'package:flutter/material.dart';

/// EditorView
/// 
/// This is the main canvas/editor view for displaying and interacting with nodes.
/// Users can pan, zoom, and drag nodes. The canvas automatically resizes to always
/// fit all nodes while keeping them interactable. Nodes are represented as 
/// NodeItem widgets and data is stored in NodeData objects.
/// 
/// This view uses an InteractiveViewer for pan/zoom, a Stack for node placement,
/// and a dynamically sized SizedBox to ensure all nodes stay inside the canvas
/// and remain hittable.
class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  /// Controller for InteractiveViewer transformation (pan/zoom)
  final TransformationController _controller = TransformationController();

  /// Offset between the user's touch and node position during dragging
  Offset? grabOffset;

  /// Canvas boundaries
  /// _minX/_minY represent the top-left corner of the canvas in world coordinates
  /// _maxX/_maxY represent the bottom-right corner of the canvas in world coordinates
  /// These boundaries expand dynamically to contain all nodes, but currently 
  /// shrinking or moving the origin causes other nodes to shift when moving left/up
  double _minX = 0;
  double _minY = 0;
  double _maxX = 500;
  double _maxY = 500;

  /// Padding around nodes so they are never at the very edge
  final double _padding = 100.0;

  /// Converts a global screen position to a canvas/world position
  /// using the inverse of the current InteractiveViewer transformation
  Offset _toScene(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final local = renderBox?.globalToLocal(globalPosition) ?? Offset.zero;
    return MatrixUtils.transformPoint(_controller.value.clone()..invert(), local);
  }

  /// Updates the canvas boundaries (_minX, _minY, _maxX, _maxY) based on
  /// all node positions. The canvas expands to ensure nodes are never outside
  /// the visible and interactable area. 
  /// 
  /// Note: Shrinking or moving _minX/_minY currently causes all nodes to shift
  /// when moving nodes to the left or top, because node positions are calculated
  /// relative to _minX/_minY. This is why dragging a node up/left moves other nodes.
  void _updateCanvasBounds(List<NodeData> nodes) {
    if (nodes.isEmpty) return;

    // Compute min/max coordinates of all nodes
    double nodesMinX = nodes.map((n) => n.position.dx).reduce((a, b) => a < b ? a : b);
    double nodesMinY = nodes.map((n) => n.position.dy).reduce((a, b) => a < b ? a : b);
    double nodesMaxX = nodes.map((n) => n.position.dx).reduce((a, b) => a > b ? a : b);
    double nodesMaxY = nodes.map((n) => n.position.dy).reduce((a, b) => a > b ? a : b);

    // Expand canvas if nodes exceed current edges
    if (nodesMinX - _padding < _minX) _minX = nodesMinX - _padding;
    if (nodesMinY - _padding < _minY) _minY = nodesMinY - _padding;
    if (nodesMaxX + _padding > _maxX) _maxX = nodesMaxX + _padding;
    if (nodesMaxY + _padding > _maxY) _maxY = nodesMaxY + _padding;

    // Shrinking logic (currently causes other nodes to shift)
    // Left/top shrink
    if (nodesMinX - _padding > _minX) _minX = nodesMinX - _padding;
    if (nodesMinY - _padding > _minY) _minY = nodesMinY - _padding;

    // Right/bottom shrink
    if (nodesMaxX + _padding < _maxX) _maxX = nodesMaxX + _padding;
    if (nodesMaxY + _padding < _maxY) _maxY = nodesMaxY + _padding;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: nodeManager,
      builder: (context, _) {
        // Retrieve all nodes from the nodeManager as a list
        final List<NodeData> nodes = nodeManager.nodes.values.toList()
          ..sort((a, b) => a.lastModified.compareTo(b.lastModified));

        // Update the canvas size based on current node positions
        _updateCanvasBounds(nodes);

        // Compute canvas size from min/max boundaries
        final canvasWidth = _maxX - _minX;
        final canvasHeight = _maxY - _minY;

        return InteractiveViewer(
          transformationController: _controller,
          minScale: 0.2,
          maxScale: 10,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          child: ColoredBox(
            color: Colors.orange,
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: nodes.map((node) {
                  // Calculate node position relative to canvas top-left
                  // This is why moving left/up shifts other nodes:
                  // when _minX/_minY changes, all nodes' relative positions change
                  final left = node.position.dx - _minX;
                  final top = node.position.dy - _minY;

                  return Positioned(
                    key: ValueKey(node.id),
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onPanStart: (details) {
                        // Calculate offset between user's touch and node position
                        final scenePos = _toScene(details.globalPosition);
                        grabOffset = scenePos - node.position;
                        nodeManager.focus(node.id);
                      },
                      onPanUpdate: (details) {
                        // Update node position as user drags
                        final scenePos = _toScene(details.globalPosition);
                        nodeManager.updatePosition(
                          node.id,
                          scenePos - (grabOffset ?? Offset.zero),
                        );
                      },
                      onPanEnd: (_) => grabOffset = null,
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

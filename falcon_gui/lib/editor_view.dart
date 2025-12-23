import 'package:falcon_gui/node_data.dart';
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

  /// Canvas bounds
  double _minX = 0;
  double _minY = 0;
  double _maxX = 500;
  double _maxY = 500;

  /// Padding around nodes
  final double _padding = 300;

  /// Visual offset applied to all nodes to counter negative growth
  double _visualOffsetX = 0;
  double _visualOffsetY = 0;

  /// Historical min values to detect canvas expansion
  double _historicalMinX = 0;
  double _historicalMinY = 0;

  /// Converts global screen position to world coordinates
  Offset _toScene(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final local = renderBox?.globalToLocal(globalPosition) ?? Offset.zero;
    return MatrixUtils.transformPoint(
      _controller.value.clone()..invert(),
      local,
    );
  }

  /// Update canvas boundaries to fit all nodes
  /// When nodes move to negative positions, the canvas grows, and we
  /// counter-shift all nodes so they visually stay in place.
  /// This version modifies actual node positions instead of just using a visual
  /// offset.
  void _updateCanvasBounds(List<NodeData> nodes) {
    if (nodes.isEmpty) return;

    // 1. Find min/max coordinates of nodes in world space
    final nodesMinX = nodes
        .map((n) => n.position.dx)
        .reduce((a, b) => a < b ? a : b);
    final nodesMinY = nodes
        .map((n) => n.position.dy)
        .reduce((a, b) => a < b ? a : b);
    final nodesMaxX = nodes
        .map((n) => n.position.dx)
        .reduce((a, b) => a > b ? a : b);
    final nodesMaxY = nodes
        .map((n) => n.position.dy)
        .reduce((a, b) => a > b ? a : b);

    // 2. Determine required canvas bounds including padding
    final requiredMinX = nodesMinX - _padding;
    final requiredMinY = nodesMinY - _padding;
    final requiredMaxX = nodesMaxX + _padding * 1.5;
    final requiredMaxY = nodesMaxY + _padding * 1.5;

    // 3. Calculate how much canvas expands into negative space
    final deltaX = requiredMinX < 0.0 ? -requiredMinX : 0.0;
    final deltaY = requiredMinY < 0.0 ? -requiredMinY : 0.0;

    // 4. Determine actual visual offset to counter canvas growth
    // Only increase offset, never decrease, to prevent "jumping"
    final newVisualOffsetX = deltaX > _historicalMinX
        ? deltaX
        : _historicalMinX;
    final newVisualOffsetY = deltaY > _historicalMinY
        ? deltaY
        : _historicalMinY;

    // 5. Calculate how much shift is needed for nodes this frame
    final shiftX = newVisualOffsetX - _visualOffsetX;
    final shiftY = newVisualOffsetY - _visualOffsetY;

    // 6. Apply shift to all nodes to counter canvas growth
    if (shiftX != 0.0 || shiftY != 0.0) {
      for (final node in nodes) {
        nodeManager.updatePosition(
          node.id,
          node.position.translate(shiftX, shiftY),
        );
      }
    }

    // 7. Update visual offset and historical min values
    _visualOffsetX = newVisualOffsetX;
    _visualOffsetY = newVisualOffsetY;
    _historicalMinX = _visualOffsetX;
    _historicalMinY = _visualOffsetY;

    // 8. Update canvas bounds ensuring it never shrinks
    _minX = _minX > requiredMinX ? _minX : requiredMinX;
    _minY = _minY > requiredMinY ? _minY : requiredMinY;
    _maxX = _maxX > requiredMaxX ? _maxX : requiredMaxX;
    _maxY = _maxY > requiredMaxY ? _maxY : requiredMaxY;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: nodeManager,
      builder: (context, _) {
        // 1. Convert nodes map to list and sort by lastModified
        final nodes = nodeManager.nodes.values.toList()
          ..sort((a, b) => a.lastModified.compareTo(b.lastModified));

        // 2. Update canvas bounds and compute visual offsets
        _updateCanvasBounds(nodes);

        // 3. Total canvas size including negative offset padding
        final canvasWidth = _maxX + _visualOffsetX;
        final canvasHeight = _maxY + _visualOffsetY;

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
                  // 4. Apply visual offset to node positions
                  //    This counteracts canvas growth in negative direction
                  final left = node.position.dx + _visualOffsetX;
                  final top = node.position.dy + _visualOffsetY;

                  return Positioned(
                    key: ValueKey(node.id),
                    left: left,
                    top: top,
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

import 'package:falcon_gui/node_data.dart';
import 'package:falcon_gui/node_manager.dart';
import 'package:flutter/material.dart';

class DraggableNode extends StatefulWidget {
  const DraggableNode({
    required this.node,
    required this.onFocus,
    required this.onDrag,
    super.key,
  });

  final NodeData node;
  final void Function(Offset) onDrag;
  final void Function() onFocus;

  @override
  State<DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<DraggableNode> {
  Offset? grabOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.move,
            child: GestureDetector(
              onPanStart: (details) {
                final stackBox = context
                    .findAncestorRenderObjectOfType<RenderBox>()!;
                final localPosition = stackBox.globalToLocal(
                  details.globalPosition,
                );
                grabOffset = localPosition - widget.node.position;
              },
              onPanUpdate: (details) {
                final stackBox = context
                    .findAncestorRenderObjectOfType<RenderBox>()!;
                final localPosition = stackBox.globalToLocal(
                  details.globalPosition,
                );
                widget.onDrag(localPosition - (grabOffset ?? Offset.zero));
              },
              onPanEnd: (_) => grabOffset = null,
              onTapDown: (details) => widget.onFocus(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.node.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      color: Colors.white,
                      onPressed: () =>
                          nodeManager.duplicateNode(widget.node.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Content of the node goes here'),
                Text('another line'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

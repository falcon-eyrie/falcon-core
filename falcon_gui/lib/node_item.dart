import 'package:falcon_gui/node_data.dart';
import 'package:falcon_gui/node_manager.dart';
import 'package:flutter/material.dart';

class NodeItem extends StatefulWidget {
  const NodeItem({
    required this.node,
    super.key,
  });

  final NodeData node;

  @override
  State<NodeItem> createState() => _NodeItemState();
}

class _NodeItemState extends State<NodeItem> {
  final GlobalKey _key = GlobalKey();
  final List<String> _lines = ['Content of the node goes here', 'another line'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  void _reportSize() {
    final context = _key.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;

    nodeManager.onNodeSizeUpdated(
      id: widget.node.id,
      newSize: size,
    );
  }

  void _addLine() {
    setState(() {
      _lines.add('New line ${_lines.length + 1}');
    });

    // Wait for the frame to complete to report the new size
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.node.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    color: Colors.white,
                    tooltip: 'Add line',
                    onPressed: _addLine,
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: Colors.white,
                    onPressed: () =>
                        nodeManager.duplicateNode(id: widget.node.id),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _lines.map(Text.new).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:falcon_gui/draggable_node.dart';
import 'package:falcon_gui/node_data.dart';
import 'package:falcon_gui/node_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  int? connectingFrom;
  Offset offset = Offset.zero;
  double scale = 1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: nodeManager,
      builder: (context, _) {
        final nodes = nodeManager.nodes.values.toList()
          ..sort((a, b) => a.lastModified.compareTo(b.lastModified));

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              setState(() {
                final delta = event.scrollDelta.dy * -0.01;
                scale *= 1 + delta;
                scale = scale.clamp(0.3, 3.0);
              });
            }
          },
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        offset += details.delta;
                      });
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),

                Transform(
                  transform: Matrix4.translationValues(offset.dx, offset.dy, 0)
                    ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
                  child: Stack(
                    children: [
                      ...nodes.map((node) {
                        return Positioned(
                          key: ValueKey(node.id),
                          left: node.position.dx,
                          top: node.position.dy,
                          child: DraggableNode(
                            node: node,
                            onFocus: () => nodeManager.focus(node.id),
                            onDrag: (offset) =>
                                nodeManager.updatePosition(node.id, offset),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

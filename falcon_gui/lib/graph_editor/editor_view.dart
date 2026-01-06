import 'package:falcon_gui/graph_editor/processor_item.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// EditorView
///
/// Main canvas/editor view for Linux desktop. Users can pan,
/// zoom, and drag processors.
class EditorView extends StatelessWidget {
  const EditorView({super.key});

  /// Converts global screen position to world coordinates
  Offset _toScene(Offset globalPosition, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.globalToLocal(globalPosition) ?? Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphManager,
      builder: (context, _) {
        final isCreatingConnection = graphManager.selectedPortUniqueId != null;
        return MouseRegion(
          cursor: isCreatingConnection
              ? SystemMouseCursors.alias
              : MouseCursor.defer,
          onHover: (event) {
            final scenePosition = _toScene(event.position, context);
            graphManager.updateCursorPosition(scenePosition);
          },
          child: Listener(
            onPointerDown: (event) {
              if (event.buttons == kSecondaryMouseButton) {
                graphManager.cancelPortSelection();

                // Check if clicking on a connection line
                final scenePosition = _toScene(event.position, context);
                graphManager.removeConnectionAtPosition(scenePosition);
              }
            },
            child: InteractiveViewer(
              interactionEndFrictionCoefficient: 0.000000001,
              transformationController: graphManager.transformationController,
              minScale: 0.01,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              child: SizedBox(
                height: graphManager.canvasSize.height,
                width: graphManager.canvasSize.width,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      painter: ConnectionPainter(
                        lineColor: const Color(0xFF208991),
                      ),
                      size: Size(
                        graphManager.canvasSize.width,
                        graphManager.canvasSize.height,
                      ),
                    ),
                    ...graphManager.processors.map((processor) {
                      return Positioned(
                        key: ValueKey(processor.id),
                        left: processor.uiMetadata.position.dx,
                        top: processor.uiMetadata.position.dy,
                        child: ProcessorItem(
                          onPanStart: (details) {
                            final scenePosition = _toScene(
                              details.globalPosition,
                              context,
                            );
                            graphManager.onOnProcessorDragStart(
                              id: processor.id,
                              scenePosition: scenePosition,
                            );
                          },
                          onPanUpdate: (details) {
                            final scenePosition = _toScene(
                              details.globalPosition,
                              context,
                            );
                            graphManager.onProcessorDragUpdate(
                              id: processor.id,
                              newPos: scenePosition,
                            );
                          },
                          onPanEnd: (_) =>
                              graphManager.onProcessorDragEnd(id: processor.id),
                          onTapDown: () =>
                              graphManager.onProcessorClicked(id: processor.id),
                          processor: processor,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ConnectionPainter extends CustomPainter {
  ConnectionPainter({
    required this.lineColor,
  });
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Draw temporary connection line
    final tempLine = graphManager.tempConnectionLinePosition;
    if (tempLine != null) {
      final path = Path()
        ..moveTo(tempLine.startPos.dx, tempLine.startPos.dy)
        ..cubicTo(
          tempLine.startPos.dx + 100,
          tempLine.startPos.dy,
          tempLine.endPos.dx - 100,
          tempLine.endPos.dy,
          tempLine.endPos.dx,
          tempLine.endPos.dy,
        );
      canvas.drawPath(path, paint);
    }

    // Draw existing connections
    for (final connPos in graphManager.connectionPositions) {
      final path = Path()
        ..moveTo(connPos.startPos.dx, connPos.startPos.dy)
        ..cubicTo(
          connPos.startPos.dx + 100,
          connPos.startPos.dy,
          connPos.endPos.dx - 100,
          connPos.endPos.dy,
          connPos.endPos.dx,
          connPos.endPos.dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) => true;
}

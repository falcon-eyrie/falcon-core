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
        graphManager.onEditorViewRendered();

        final isCreatingConnection = graphManager.selectedPortUniqueId != null;
        return MouseRegion(
          cursor: isCreatingConnection
              ? SystemMouseCursors.alias
              : graphManager.hoveredConnection != null
              ? SystemMouseCursors.noDrop
              : SystemMouseCursors.basic,
          onHover: (event) {
            final scenePosition = _toScene(event.position, context);
            graphManager.updateCursorPosition(scenePosition);
          },
          child: Listener(
            onPointerDown: (event) {
              if (event.buttons == kSecondaryMouseButton) {
                graphManager
                  ..cancelPortSelection()
                  ..maybeRemoveConnectionAtPosition();
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
                    if (graphManager.shouldRenderConnections) ...[
                      CustomPaint(
                        painter: ConnectionPainter(
                          connectedColor: Colors.green,
                          newConnectionColor: Colors.grey,
                        ),
                        size: Size(
                          graphManager.canvasSize.width,
                          graphManager.canvasSize.height,
                        ),
                      ),
                    ],
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
                            graphManager.onProcessorDragStart(
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
    required this.connectedColor,
    required this.newConnectionColor,
  });
  final Color connectedColor;
  final Color newConnectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = newConnectionColor
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
    paint.color = connectedColor;

    // Draw existing connections
    for (final connPos in graphManager.connectionPositions) {
      if (connPos.connection == graphManager.hoveredConnection) {
        paint.color = Colors.yellow;
      } else {
        paint.color = connectedColor;
      }
      final path = Path()
        ..moveTo(connPos.startPos.dx, connPos.startPos.dy)
        ..cubicTo(
          connPos.startPos.dx + 200,
          connPos.startPos.dy,
          connPos.endPos.dx - 200,
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

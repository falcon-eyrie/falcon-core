import 'package:falcon_gui/graph_editor/processor_item.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

/// EditorView
///
/// Main canvas/editor view for Linux desktop. Users can pan,
/// zoom, and drag processors.
class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  bool _isPanning = false;

  @override
  Widget build(BuildContext context) {
    graphManager.viewportSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: graphManager,
      builder: (context, _) {
        graphManager.onEditorViewRendered();

        final isCreatingConnection = graphManager.selectedPortUniqueId != null;

        final SystemMouseCursor cursor;

        if (isCreatingConnection) {
          cursor = SystemMouseCursors.alias;
        } else if (_isPanning) {
          cursor = SystemMouseCursors.move;
        } else if (graphManager.hoveredConnection != null) {
          cursor = SystemMouseCursors.noDrop;
        } else {
          cursor = SystemMouseCursors.basic;
        }

        return MouseRegion(
          cursor: cursor,
          child: Listener(
            onPointerDown: (event) {
              if (event.buttons == kSecondaryMouseButton) {
                graphManager
                  ..cancelPortSelection()
                  ..maybeRemoveConnectionAtPosition();
              }

              if (event.buttons == kPrimaryMouseButton) {
                setState(() => _isPanning = true);
              }
            },
            onPointerUp: (event) {
              if (event.buttons == 0) {
                setState(() => _isPanning = false);
              }
            },
            onPointerCancel: (_) {
              setState(() => _isPanning = false);
            },
            onPointerHover: (event) {
              graphManager.updateCursorPosition(event.position);
            },

            child: Stack(
              children: [
                InteractiveViewer(
                  interactionEndFrictionCoefficient: 0.000000001,
                  transformationController:
                      graphManager.transformationController,
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
                              readonly: !falconManager.canEditGraph,
                              onPanStart: (details) {
                                graphManager.onProcessorDragStart(
                                  id: processor.id,
                                  scenePosition: details.globalPosition,
                                );
                              },
                              onPanUpdate: (details) {
                                graphManager.onProcessorDragUpdate(
                                  id: processor.id,
                                  newPos: details.globalPosition,
                                );
                              },
                              onPanEnd: (_) => graphManager.onProcessorDragEnd(
                                id: processor.id,
                              ),
                              onTapDown: () => graphManager.onProcessorClicked(
                                id: processor.id,
                              ),
                              processor: processor,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (graphManager.selectedPortUniqueId != null) ...[
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 12,
                    child: _CancelNewConnectionModeInfo(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CancelNewConnectionModeInfo extends StatelessWidget {
  const _CancelNewConnectionModeInfo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.c.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              RemixIcons.mouse_line,
              size: 16,
              color: context.c.onSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Select another port to create connection. '
              'Right click to cancel',
              style: TextStyle(
                color: context.c.onSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

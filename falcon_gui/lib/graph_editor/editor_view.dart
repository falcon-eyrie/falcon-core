import 'package:falcon_gui/graph_editor/processor_item.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:flutter/material.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCanvas());
  }

  void _centerCanvas() {
    final viewportSize = MediaQuery.of(context).size;
    final canvasSize = graphManager.canvasSize;
    graphManager.transformationController.value = Matrix4.identity()
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
      animation: graphManager,
      builder: (context, _) {
        return InteractiveViewer(
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
              children: graphManager.processors.map((processor) {
                return Positioned(
                  key: ValueKey(processor.id),
                  left: processor.uiMetadata.position.dx,
                  top: processor.uiMetadata.position.dy,
                  child: ProcessorItem(
                    onPanStart: (details) {
                      final scenePosition = _toScene(details.globalPosition);
                      graphManager.onOnProcessorDragStart(
                        id: processor.id,
                        scenePosition: scenePosition,
                      );
                    },
                    onPanUpdate: (details) {
                      final scenePosition = _toScene(details.globalPosition);
                      graphManager.onProcessorDragUpdate(
                        id: processor.id,
                        newPos: scenePosition,
                      );
                    },
                    onPanEnd: (_) =>
                        graphManager.onProcessorDragEnd(id: processor.id),
                    onTapDown: (_) =>
                        graphManager.onProcessorClicked(id: processor.id),
                    processor: processor,
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

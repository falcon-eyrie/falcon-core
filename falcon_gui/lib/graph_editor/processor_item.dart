import 'package:falcon_gui/graph_editor/processor_options.dart';
import 'package:falcon_gui/graph_editor/processor_ports.dart';
import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class ProcessorItem extends StatelessWidget {
  const ProcessorItem({
    required this.processor,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onTapDown,
    super.key,
  });

  final Processor processor;

  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(DragEndDetails)? onPanEnd;
  final void Function(TapDownDetails)? onTapDown;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown,
      child: Container(
        key: ValueKey(processor.id),
        width: 300,
        decoration: BoxDecoration(
          border: Border.all(color: context.c.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(8),
          color: context.c.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: _Header(processor: processor),
            ),
            ProcessorPortsView(processor: processor),
            const Divider(),
            ProcessorOptionsView(processor: processor),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.processor});

  final Processor processor;

  @override
  Widget build(BuildContext context) {
    final color =
        processor.uiMetadata.color ??
        DefaultProcessorColor.byClassName(className: processor.className) ??
        context.c.primary;
    return MouseRegion(
      cursor: processor.isTemplate
          ? MouseCursor.defer
          : SystemMouseCursors.move,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    processor.id,
                    style: const TextStyle(
                      color: Color(0xffffffff),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    processor.className,
                    style: const TextStyle(
                      color: Color(0xffffffff),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            if (!processor.isTemplate) ...[
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 16,
                  color: Color(0xffffffff),
                ),
                color: context.c.onPrimary,
                onPressed: () => graphManager.removeProcessor(id: processor.id),
              ),

              const SizedBox(width: 4),
            ],
            IconButton(
              icon: Icon(
                processor.isTemplate ? Icons.add : Icons.copy,
                size: 16,
                color: const Color(0xffffffff),
              ),
              color: context.c.onPrimary,
              onPressed: () =>
                  graphManager.duplicateProcessor(processor: processor),
            ),
          ],
        ),
      ),
    );
  }
}

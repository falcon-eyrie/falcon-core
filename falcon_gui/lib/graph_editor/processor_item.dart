import 'package:falcon_gui/graph_editor/processor_options.dart';
import 'package:falcon_gui/graph_editor/processor_ports.dart';
import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class ProcessorItem extends StatefulWidget {
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
  State<ProcessorItem> createState() => _ProcessorItemState();
}

class _ProcessorItemState extends State<ProcessorItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _isExpanded = !widget.processor.isTemplate;

    // This could be a nice to have
    //_isExpanded = widget.processor.uiMetadata.isExpanded ?? false;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTapDown,
      child: Container(
        key: ValueKey(widget.processor.id),
        width: 400,
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
              onPanStart: widget.onPanStart,
              onPanUpdate: widget.onPanUpdate,
              onPanEnd: widget.onPanEnd,
              child: _Header(
                processor: widget.processor,
                onExpandToggle: _toggleExpanded,
                isExpanded: _isExpanded,
              ),
            ),
            IgnorePointer(
              ignoring: widget.processor.isTemplate,
              child: ColorFiltered(
                colorFilter: widget.processor.isTemplate
                    ? greyScaleFilter
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),

                child: ProcessorPortsView(processor: widget.processor),
              ),
            ),
            if (_isExpanded) ...[
              const Divider(),
              IgnorePointer(
                ignoring: widget.processor.isTemplate,
                child: ColorFiltered(
                  colorFilter: widget.processor.isTemplate
                      ? greyScaleFilter
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                  child: ProcessorOptionsView(processor: widget.processor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.processor,
    required this.onExpandToggle,
    required this.isExpanded,
  });

  final Processor processor;
  final VoidCallback onExpandToggle;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final color =
        processor.uiMetadata.color ??
        DefaultProcessorColor.byClassName(className: processor.className);
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
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: const Color(0xffffffff),
              ),
              color: context.c.onPrimary,
              onPressed: onExpandToggle,
            ),
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

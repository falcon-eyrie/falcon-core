import 'package:falcon_gui/model/processor_templates.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

enum ActiveProcessorCategory {
  sources,
  intermediates,
  sinks,
}

class ProcessorsPanel extends StatefulWidget {
  const ProcessorsPanel({required this.activeCategory, super.key});

  final ActiveProcessorCategory activeCategory;

  @override
  State<ProcessorsPanel> createState() => _ProcessorsPanelState();
}

class _ProcessorsPanelState extends State<ProcessorsPanel> {
  String _hoveredProcessorId = '';

  @override
  Widget build(BuildContext context) {
    final processors = switch (widget.activeCategory) {
      ActiveProcessorCategory.sources => sourceTemplates.values.toList(),
      ActiveProcessorCategory.intermediates =>
        intermediateTemplates.values.toList(),
      ActiveProcessorCategory.sinks => sinkTemplates.values.toList(),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      width: 800,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: processors.map(
          (processor) {
            final isHovered = _hoveredProcessorId == processor.className;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (event) =>
                  setState(() => _hoveredProcessorId = processor.className),
              onExit: (event) => setState(() => _hoveredProcessorId = ''),
              child: GestureDetector(
                onTap: () =>
                    graphManager.duplicateProcessor(processor: processor),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? context.c.secondary
                        : DefaultProcessorColor.byClassName(
                            className: processor.className,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        processor.className,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isHovered ? context.c.onSecondary : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        RemixIcons.function_add_line,
                        size: 16,
                        color: isHovered ? context.c.onSecondary : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

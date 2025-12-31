import 'package:falcon_gui/graph_editor/processor_item.dart';
import 'package:falcon_gui/state/processor_templates.dart';
import 'package:flutter/material.dart';

class ProcessorsPanel extends StatelessWidget {
  const ProcessorsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ListView.builder(
        itemBuilder: (context, index) {
          final processor = processorTemplates.values.elementAtOrNull(
            index,
          );

          if (processor == null) {
            return null;
          }
          return Padding(
            padding: const EdgeInsets.all(8),
            child: ProcessorItem(processor: processor),
          );
        },
      ),
    );
  }
}

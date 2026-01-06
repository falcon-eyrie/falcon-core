import 'package:falcon_gui/graph_editor/processor_item.dart';
import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/processor_definitions.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class ProcessorsPanel extends StatelessWidget {
  const ProcessorsPanel({super.key});

  bool isFirstIntermediateProcessor(int index, Processor processor) {
    return processor.isIntermediate &&
        processorDefinitions.values.where((p) => p.isSource).length == index;
  }

  bool isFirstSinkProcessor(int index, Processor processor) {
    return processor.isSink &&
        processorDefinitions.values
                .where((p) => p.isSource || p.isIntermediate)
                .length ==
            index;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      color: context.c.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                final processor = processorDefinitions.values.elementAtOrNull(
                  index,
                );

                if (processor == null) {
                  return null;
                }

                String? processorCategoryText;

                if (index == 0) {
                  processorCategoryText = 'Sources';
                } else if (isFirstIntermediateProcessor(index, processor)) {
                  processorCategoryText = 'Intermediates';
                } else if (isFirstSinkProcessor(index, processor)) {
                  processorCategoryText = 'Sinks';
                }

                if (processorCategoryText != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0) ...[
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Available Processors',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          processorCategoryText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: ProcessorItem(processor: processor),
                      ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: ProcessorItem(processor: processor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

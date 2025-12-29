import 'package:falcon_gui/graph_editor/proessor_item.dart';
import 'package:falcon_gui/state/example_graph.dart';
import 'package:flutter/material.dart';

class ProcessorsPanel extends StatelessWidget {
  const ProcessorsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ListView.builder(
        itemBuilder: (context, index) {
          final processor = exampleGraph.processors.values.elementAtOrNull(
            index,
          );

          if (processor == null) {
            return null;
          }
          return ProcessorItem(processor: processor);
        },
      ),
    );
  }
}

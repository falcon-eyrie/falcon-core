import 'package:falcon_gui/graph_editor/editor_view.dart';
import 'package:falcon_gui/graph_editor/processors_panel.dart';
import 'package:flutter/material.dart';

class GraphEditor extends StatelessWidget {
  const GraphEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          // width: 300,
          child: ProcessorsPanel(),
        ),
        Expanded(child: EditorView()),
      ],
    );
  }
}

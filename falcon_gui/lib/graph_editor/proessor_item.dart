import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/node_manager.dart';
import 'package:flutter/material.dart';

class ProcessorItem extends StatefulWidget {
  const ProcessorItem({
    required this.processor,
    super.key,
  });

  final Processor processor;

  @override
  State<ProcessorItem> createState() => _ProcessorItemState();
}

class _ProcessorItemState extends State<ProcessorItem> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  void _reportSize() {
    final context = _key.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;

    graphManager.onNodeSizeUpdated(
      id: widget.processor.id,
      newSize: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.processor.id,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.processor.className,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      widget.processor.isTemplate ? Icons.add : Icons.copy,
                      size: 16,
                    ),
                    color: Colors.white,
                    onPressed: () => graphManager.duplicateProcessor(
                      processor: widget.processor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Column(
                  children: widget.processor.inputPorts
                      .map(
                        (port) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ProcessorPortItem(
                            isInput: true,
                            port: port,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                Column(
                  children: widget.processor.outputPorts
                      .map(
                        (port) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ProcessorPortItem(
                            isInput: false,
                            port: port,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const Divider(),

          ...widget.processor.options.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: switch (entry.value) {
                final IntOption intOption => ProcessorIntOptionItem(
                  optionName: entry.key,
                  option: intOption,
                  onChanged: (newValue) {
                    graphManager.updateIntOption(
                      processorId: widget.processor.id,
                      optionName: entry.key,
                      newValue: newValue,
                    );
                  },
                ),
                DoubleOption doubleOption => Text(
                  '${entry.key}: ${doubleOption.value}',
                ),
                StringOption stringOption => Text(
                  '${entry.key}: ${stringOption.value}',
                ),
                BoolOption boolOption => Text(
                  '${entry.key}: ${boolOption.value}',
                ),
                OneOfOption oneOfOption => Text(
                  '${entry.key}: ${oneOfOption.value}',
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget for editing an integer option of a processor.
class ProcessorIntOptionItem extends StatelessWidget {
  const ProcessorIntOptionItem({
    required this.optionName,
    required this.option,
    required this.onChanged,
    super.key,
  });

  final String optionName;
  final IntOption option;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(optionName),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: option.value.toString(),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                onChanged(intValue);
              }
            },
          ),
        ),
      ],
    );
  }
}

class ProcessorPortItem extends StatelessWidget {
  const ProcessorPortItem({
    required this.isInput,
    required this.port,
    super.key,
  });
  final Port port;

  final bool isInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isInput ? Colors.blue : Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

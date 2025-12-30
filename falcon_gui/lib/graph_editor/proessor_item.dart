import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/node_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                final IntOption intOption => IntOptionField(
                  name: entry.key,
                  option: intOption,
                  onChanged: (newValue) {
                    graphManager.updateOptionValue(
                      processorId: widget.processor.id,
                      optionName: entry.key,
                      newValue: newValue,
                    );
                  },
                ),

                final DoubleOption doubleOption => DoubleOptionField(
                  name: entry.key,
                  option: doubleOption,
                  onChanged: (newValue) {
                    graphManager.updateOptionValue(
                      processorId: widget.processor.id,
                      optionName: entry.key,
                      newValue: newValue,
                    );
                  },
                ),

                final StringOption stringOption => StringOptionField(
                  name: entry.key,
                  option: stringOption,
                  onChanged: (newValue) {
                    graphManager.updateOptionValue(
                      processorId: widget.processor.id,
                      optionName: entry.key,
                      newValue: newValue,
                    );
                  },
                ),

                final BoolOption boolOption => BoolOptionField(
                  name: entry.key,
                  option: boolOption,
                  onChanged: (newValue) {
                    graphManager.updateOptionValue(
                      processorId: widget.processor.id,
                      optionName: entry.key,
                      newValue: newValue,
                    );
                  },
                ),

                final OneOfOption oneOfOption => OneOfOptionField(
                  name: entry.key,
                  option: oneOfOption,
                  onChanged: (newValue) {
                    graphManager.updateOptionValue(
                      processorId: widget.processor.id,
                      optionName: entry.key,
                      newValue: newValue,
                    );
                  },
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class IntOptionField extends StatelessWidget {
  const IntOptionField({
    required this.name,
    required this.option,
    required this.onChanged,
    super.key,
  });

  final String name;
  final IntOption option;
  final ValueChanged<IntOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: option.value.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                var text = newValue.text;

                if (!RegExp(r'^-?\d*-?$').hasMatch(text)) {
                  return oldValue;
                }

                if (text.endsWith('-') && text.length > 1) {
                  text = text.substring(0, text.length - 1);
                }

                return TextEditingValue(
                  text: text,
                  selection: TextSelection.collapsed(offset: text.length),
                );
              }),
            ],
            onChanged: (v) {
              final value = int.tryParse(v);
              if (value != null) onChanged(IntOption(value));
            },
          ),
        ),
      ],
    );
  }
}

/// DOUBLE
class DoubleOptionField extends StatelessWidget {
  const DoubleOptionField({
    required this.name,
    required this.option,
    required this.onChanged,
    super.key,
  });

  final String name;
  final DoubleOption option;
  final ValueChanged<DoubleOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: option.value.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^-?\d*\.?\d*$'),
              ),
            ],
            onChanged: (v) {
              final value = double.tryParse(v);
              if (value != null) {
                onChanged(DoubleOption(value));
              }
            },
          ),
        ),
      ],
    );
  }
}

/// STRING
class StringOptionField extends StatelessWidget {
  const StringOptionField({
    required this.name,
    required this.option,
    required this.onChanged,
    super.key,
  });

  final String name;
  final StringOption option;
  final ValueChanged<StringOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: option.value,
            onChanged: (value) => onChanged(StringOption(value)),
          ),
        ),
      ],
    );
  }
}

/// BOOL
class BoolOptionField extends StatelessWidget {
  const BoolOptionField({
    required this.name,
    required this.option,
    required this.onChanged,
    super.key,
  });

  final String name;
  final BoolOption option;
  final ValueChanged<BoolOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name),
        const SizedBox(width: 8),
        Switch(
          value: option.value,
          onChanged: (value) => onChanged(BoolOption(value)),
        ),
      ],
    );
  }
}

/// ONE OF
class OneOfOptionField extends StatelessWidget {
  const OneOfOptionField({
    required this.name,
    required this.option,
    required this.onChanged,
    super.key,
  });

  final String name;
  final OneOfOption option;
  final ValueChanged<OneOfOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: option.value,
            items: option.allowed
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(OneOfOption(v, option.allowed));
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

import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    graphManager.onProcessorLayoutSizeUpdated(
      id: widget.processor.id,
      newSize: box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
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
            onPanStart: widget.onPanStart,
            onPanUpdate: widget.onPanUpdate,
            onPanEnd: widget.onPanEnd,
            onTapDown: widget.onTapDown,
            child: _Header(processor: widget.processor),
          ),
          _Ports(processor: widget.processor),
          const Divider(),
          ...widget.processor.options.entries.map(
            (entry) {
              void onChanged(OptionValue<dynamic> newValue) {
                graphManager.updateOptionValue(
                  processorId: widget.processor.id,
                  optionName: entry.key,
                  newValue: newValue,
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: switch (entry.value) {
                  final IntOption o => IntOptionField(
                    option: o,
                    onChanged: onChanged,
                  ),
                  final DoubleOption o => DoubleOptionField(
                    option: o,
                    onChanged: onChanged,
                  ),
                  final StringOption o => StringOptionField(
                    option: o,
                    onChanged: onChanged,
                  ),
                  final BoolOption o => BoolOptionField(
                    option: o,
                    onChanged: onChanged,
                  ),
                  final OneOfOption o => OneOfOptionField(
                    option: o,
                    onChanged: onChanged,
                  ),
                },
              );
            },
          ),
        ],
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

class _Ports extends StatelessWidget {
  const _Ports({required this.processor});

  final Processor processor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Column(
            children: processor.inputPorts
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ProcessorPortItem(isInput: true, port: p),
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          Column(
            children: processor.outputPorts
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ProcessorPortItem(isInput: false, port: p),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

abstract class OptionFieldBase<T extends OptionValue<dynamic>>
    extends StatelessWidget {
  const OptionFieldBase({
    required this.option,
    required this.onChanged,
    super.key,
  });

  final T option;
  final ValueChanged<T> onChanged;

  Widget buildField(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(option.displayName),
        const SizedBox(width: 8),
        Expanded(child: buildField(context)),
      ],
    );
  }
}

class IntOptionField extends OptionFieldBase<IntOption> {
  const IntOptionField({
    required super.option,
    required super.onChanged,
    super.key,
  });

  @override
  Widget buildField(BuildContext context) {
    return TextFormField(
      initialValue: option.value.toString(),
      keyboardType: TextInputType.number,
      inputFormatters: [_intFormatter],
      onChanged: (v) {
        final value = int.tryParse(v);
        if (value != null) onChanged(option.copyWith(newValue: value));
      },
    );
  }
}

class DoubleOptionField extends OptionFieldBase<DoubleOption> {
  const DoubleOptionField({
    required super.option,
    required super.onChanged,
    super.key,
  });

  @override
  Widget buildField(BuildContext context) {
    return TextFormField(
      initialValue: option.value.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
      ],
      onChanged: (v) {
        final value = double.tryParse(v);
        if (value != null) onChanged(option.copyWith(newValue: value));
      },
    );
  }
}

class StringOptionField extends OptionFieldBase<StringOption> {
  const StringOptionField({
    required super.option,
    required super.onChanged,
    super.key,
  });

  @override
  Widget buildField(BuildContext context) {
    return TextFormField(
      initialValue: option.value,
      onChanged: (v) => onChanged(option.copyWith(newValue: v)),
    );
  }
}

class BoolOptionField extends OptionFieldBase<BoolOption> {
  const BoolOptionField({
    required super.option,
    required super.onChanged,
    super.key,
  });

  @override
  Widget buildField(BuildContext context) {
    return Switch(
      value: option.value,
      onChanged: (v) => onChanged(option.copyWith(newValue: v)),
    );
  }
}

class OneOfOptionField extends OptionFieldBase<OneOfOption> {
  const OneOfOptionField({
    required super.option,
    required super.onChanged,
    super.key,
  });

  @override
  Widget buildField(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: option.value,
      items: option.allowed
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(option.copyWith(newValue: v));
      },
    );
  }
}

final _intFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) {
    var text = newValue.text;

    if (!RegExp(r'^-?\d*-?$').hasMatch(text)) return oldValue;
    if (text.endsWith('-') && text.length > 1) {
      text = text.substring(0, text.length - 1);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  },
);

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

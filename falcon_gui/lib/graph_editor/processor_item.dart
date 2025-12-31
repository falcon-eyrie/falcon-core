import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Container(
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
            onTapDown: onTapDown,
            child: _Header(processor: processor),
          ),
          _Ports(processor: processor),
          const Divider(),
          ...processor.options.entries.map(
            (entry) {
              final option = entry.value;

              void onChanged(OptionValue<dynamic> newValue) {
                graphManager.updateOptionValue(
                  processorId: processor.id,
                  optionName: entry.key,
                  newValue: newValue,
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text(option.displayName),
                    const SizedBox(width: 8),
                    Expanded(
                      child: switch (option) {
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
                    ),
                  ],
                ),
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
    extends StatefulWidget {
  const OptionFieldBase({
    required this.option,
    required this.onChanged,
    super.key,
  });

  final T option;
  final ValueChanged<T> onChanged;

  @override
  State<OptionFieldBase<T>> createState() => _OptionFieldBaseState<T>();

  TextInputType get keyboardType;

  List<TextInputFormatter> get inputFormatters;

  T parseValue(String value);
}

class _OptionFieldBaseState<T extends OptionValue<dynamic>>
    extends State<OptionFieldBase<T>> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.option.value.toString());
  }

  @override
  void didUpdateWidget(covariant OptionFieldBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option.value != widget.option.value) {
      _controller.value = TextEditingValue(
        text: widget.option.value.toString(),
        selection: TextSelection.collapsed(
          offset: widget.option.value.toString().length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: (v) {
        try {
          final parsed = widget.parseValue(v);
          widget.onChanged(parsed);
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {}
      },
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
  TextInputType get keyboardType => TextInputType.number;

  @override
  List<TextInputFormatter> get inputFormatters => [_intFormatter];

  @override
  IntOption parseValue(String value) {
    final v = int.tryParse(value);
    if (v == null) throw Exception('Invalid int');
    return option.copyWith(newValue: v);
  }
}

class DoubleOptionField extends OptionFieldBase<DoubleOption> {
  const DoubleOptionField({
    required super.option,
    required super.onChanged,
    super.key,
  });

  @override
  TextInputType get keyboardType =>
      const TextInputType.numberWithOptions(decimal: true);

  @override
  List<TextInputFormatter> get inputFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
  ];

  @override
  DoubleOption parseValue(String value) {
    final v = double.tryParse(value);
    if (v == null) throw Exception('Invalid double');
    return option.copyWith(newValue: v);
  }
}

class StringOptionField extends OptionFieldBase<StringOption> {
  const StringOptionField({
    required super.option,
    required super.onChanged,
    super.key,
  });

  @override
  TextInputType get keyboardType => TextInputType.text;

  @override
  List<TextInputFormatter> get inputFormatters => [];

  @override
  StringOption parseValue(String value) => option.copyWith(newValue: value);
}

class BoolOptionField extends StatelessWidget {
  const BoolOptionField({
    required this.option,
    required this.onChanged,
    super.key,
  });

  final BoolOption option;
  final ValueChanged<BoolOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: option.value,
      onChanged: (v) => onChanged(option.copyWith(newValue: v)),
    );
  }
}

class OneOfOptionField extends StatelessWidget {
  const OneOfOptionField({
    required this.option,
    required this.onChanged,
    super.key,
  });

  final OneOfOption option;
  final ValueChanged<OneOfOption> onChanged;

  @override
  Widget build(BuildContext context) {
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

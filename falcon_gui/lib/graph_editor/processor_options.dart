import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProcessorOptionsView extends StatelessWidget {
  const ProcessorOptionsView({required this.processor, super.key});
  final Processor processor;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                children: [
                  Text(option.displayName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
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
                        // TODO(ben): implement a better YAML editor
                        final YamlNodeOption o => Text(
                          o.value.toString(),
                        ),
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
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
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.option.value.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _onSubmitted(_controller.text);
    }
  }

  void _onSubmitted(String value) {
    try {
      final newOption = widget.parseValue(value);
      widget.onChanged(newOption);
    } catch (e, s) {
      logError(
        'Error parsing option value for ${widget.option}: $e',
        s,
      );
    }
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 32),
      child: TextFormField(
        focusNode: _focusNode,
        controller: _controller,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
      ),
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
    return Checkbox(
      value: option.value,
      onChanged: (v) => onChanged(option.copyWith(newValue: v ?? false)),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: DropdownButtonFormField<String>(
        initialValue: option.value.toLowerCase(),
        items: option.allowed
            .map(
              (v) => DropdownMenuItem(value: v.toLowerCase(), child: Text(v)),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(option.copyWith(newValue: v));
        },
      ),
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

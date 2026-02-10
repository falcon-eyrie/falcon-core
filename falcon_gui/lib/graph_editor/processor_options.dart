import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:yaml/yaml.dart';

class ProcessorOptionsView extends StatelessWidget {
  const ProcessorOptionsView({required this.processor, super.key});
  final Processor processor;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...processor.options.entries.map((entry) {
          final option = entry.value;

          void onChanged(OptionValue<dynamic> newValue) {
            graphManager.updateOptionValue(
              processorId: processor.id,
              optionName: entry.key,
              newValue: newValue,
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              final YamlListOption o => YamlListOptionField(
                option: o,
                onChanged: onChanged,
              ),
              final YamlMapOption o => YamlMapOptionField(
                option: o,
                onChanged: onChanged,
              ),
            },
          );
        }),
      ],
    );
  }
}

abstract class _OptionTextFieldBase<T extends OptionValue<dynamic>>
    extends StatefulWidget {
  const _OptionTextFieldBase({
    required this.option,
    required this.onChanged,
    super.key,
  });

  final T option;
  final ValueChanged<T> onChanged;

  @override
  State<_OptionTextFieldBase<T>> createState() =>
      _OptionTextFieldBaseState<T>();

  TextInputType get keyboardType;

  List<TextInputFormatter> get inputFormatters;

  T parseValue(String value);
}

class _OptionTextFieldBaseState<T extends OptionValue<dynamic>>
    extends State<_OptionTextFieldBase<T>> {
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
      logError('Error parsing option value for ${widget.option}: $e', s);
    }
  }

  @override
  void didUpdateWidget(covariant _OptionTextFieldBase<T> oldWidget) {
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
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      controller: _controller,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.option.displayName,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }
}

class IntOptionField extends _OptionTextFieldBase<IntOption> {
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

class DoubleOptionField extends _OptionTextFieldBase<DoubleOption> {
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

class StringOptionField extends _OptionTextFieldBase<StringOption> {
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
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(option.displayName, style: const TextStyle(fontSize: 12)),
          Checkbox(
            value: option.value,
            onChanged: (v) => onChanged(option.copyWith(newValue: v ?? false)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
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

class YamlListOptionField extends StatefulWidget {
  const YamlListOptionField({
    required this.option,
    required this.onChanged,
    super.key,
  });

  final YamlListOption option;
  final ValueChanged<YamlListOption> onChanged;

  @override
  State<YamlListOptionField> createState() => _YamlListOptionFieldState();
}

class _YamlListOptionFieldState extends State<YamlListOptionField> {
  bool _isAdding = false;

  void _submitNewItem(String value) {
    if (value.trim().isNotEmpty) {
      final newList = List<String>.from(widget.option.value.value)
        ..add(value.trim());
      widget.onChanged(
        widget.option.copyWith(
          newValue: YamlList.wrap(newList.toSet().toList()),
        ),
      );
    }
    setState(() {
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.option.displayName, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...widget.option.value.value.map(
                (item) => _YamlOptionChip(
                  onIconClicked: () {
                    final newList = List<String>.from(
                      widget.option.value.value,
                    )..remove(item);
                    widget.onChanged(
                      widget.option.copyWith(
                        newValue: YamlList.wrap(newList),
                      ),
                    );
                  },
                  icon: RemixIcons.delete_bin_line,
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (_isAdding)
                _YamlOptionChip(
                  child: IntrinsicWidth(
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'New item...',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onSubmitted: _submitNewItem,
                      onTapOutside: (_) => setState(() => _isAdding = false),
                    ),
                  ),
                )
              else
                _YamlOptionChip(
                  onIconClicked: () => setState(() => _isAdding = true),
                  icon: RemixIcons.add_line,
                  child: const Text('Add', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YamlOptionChip extends StatelessWidget {
  const _YamlOptionChip({
    required this.child,
    this.onIconClicked,
    this.icon,
  });

  final Widget child;
  final IconData? icon;
  final VoidCallback? onIconClicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: child,
          ),
          const SizedBox(width: 2),
          if (icon != null && onIconClicked != null)
            ClickableIcon(
              icon: Icon(
                icon,
                size: 12,
              ),
              onPressed: onIconClicked!,
            ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class YamlMapOptionField extends StatelessWidget {
  const YamlMapOptionField({
    required this.option,
    required this.onChanged,
    super.key,
  });

  final YamlMapOption option;
  final ValueChanged<YamlMapOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return const Text('YAML Map Editor is not implemented yet');
  }
}

final _intFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
  var text = newValue.text;

  if (!RegExp(r'^-?\d*-?$').hasMatch(text)) return oldValue;
  if (text.endsWith('-') && text.length > 1) {
    text = text.substring(0, text.length - 1);
  }

  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
});

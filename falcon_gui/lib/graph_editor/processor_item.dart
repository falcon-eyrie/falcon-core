import 'package:falcon_gui/graph_editor/processor_options.dart';
import 'package:falcon_gui/graph_editor/processor_ports.dart';
import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

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
  final void Function()? onTapDown;

  @override
  State<ProcessorItem> createState() => _ProcessorItemState();
}

class _ProcessorItemState extends State<ProcessorItem> {
  // Template processors neither store any state nor they are modifiable
  bool _isTemplateExpanded = false;
  void _toggleExpanded() {
    if (widget.processor.isTemplate) {
      setState(() {
        _isTemplateExpanded = !_isTemplateExpanded;
      });
    } else {
      graphManager.toggleProcessorExpanded(id: widget.processor.id);
    }
  }

  bool get showPorts => !widget.processor.isTemplate || _isTemplateExpanded;

  bool get _isExpanded => widget.processor.isTemplate
      ? _isTemplateExpanded
      : widget.processor.uiMetadata.isExpanded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTapDown?.call(),
      child: Container(
        key: ValueKey(widget.processor.id),
        width: 400,
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
              child: _Header(
                processor: widget.processor,
                onExpandToggle: _toggleExpanded,
                isExpanded: _isExpanded,
                onFocused: () => widget.onTapDown?.call(),
              ),
            ),
            // if (showPorts) ...[
            IgnorePointer(
              ignoring: widget.processor.isTemplate,
              child: ColorFiltered(
                colorFilter: widget.processor.isTemplate
                    ? greyScaleFilter
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),

                child: ProcessorPortsView(
                  processor: widget.processor,
                  isExpanded: _isExpanded,
                ),
              ),
            ),
            // ],
            if (_isExpanded) ...[
              const Divider(),
              IgnorePointer(
                ignoring: widget.processor.isTemplate,
                child: ColorFiltered(
                  colorFilter: widget.processor.isTemplate
                      ? greyScaleFilter
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                  child: ProcessorOptionsView(processor: widget.processor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({
    required this.processor,
    required this.onExpandToggle,
    required this.isExpanded,
    required this.onFocused,
  });

  final Processor processor;
  final VoidCallback onExpandToggle;
  final bool isExpanded;
  final VoidCallback onFocused;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _isEditing = false;

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _onNameChanged(String newName) {
    graphManager.renameProcessor(oldId: widget.processor.id, newId: newName);
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final processorColor =
        widget.processor.uiMetadata.color ??
        DefaultProcessorColor.byClassName(
          className: widget.processor.className,
        );

    final headerColor =
        graphManager.isProcessorCompatibleForSelectedPort(
          widget.processor.id,
        )
        ? processorColor
        : Colors.grey;
    return MouseRegion(
      cursor: widget.processor.isTemplate
          ? MouseCursor.defer
          : SystemMouseCursors.move,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isEditing) ...[
                    _ProcessorNameEditor(
                      processor: widget.processor,
                      onNameChanged: _onNameChanged,
                      onFocused: widget.onFocused,
                    ),
                  ] else ...[
                    MouseRegion(
                      cursor: SystemMouseCursors.text,
                      child: GestureDetector(
                        onTap: _startEditing,
                        child: Text(
                          widget.processor.id,
                          style: const TextStyle(
                            color: Color(0xffffffff),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Text(
                    widget.processor.className,
                    style: const TextStyle(
                      color: Color(0xffffffff),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.processor.isTemplate) ...[
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 16,
                  color: Color(0xffffffff),
                ),
                color: context.c.onPrimary,
                onPressed: () =>
                    graphManager.removeProcessor(id: widget.processor.id),
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              icon: Icon(
                widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: const Color(0xffffffff),
              ),
              color: context.c.onPrimary,
              onPressed: widget.onExpandToggle,
            ),
            IconButton(
              icon: Icon(
                widget.processor.isTemplate ? Icons.add : Icons.copy,
                size: 20,
                color: const Color(0xffffffff),
              ),
              color: context.c.onPrimary,
              onPressed: () =>
                  graphManager.duplicateProcessor(processor: widget.processor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessorNameEditor extends StatefulWidget {
  const _ProcessorNameEditor({
    required this.processor,
    required this.onFocused,
    required this.onNameChanged,
  });

  final Processor processor;
  final void Function(String) onNameChanged;
  final VoidCallback onFocused;
  @override
  State<_ProcessorNameEditor> createState() => _ProcessorNameEditorState();
}

class _ProcessorNameEditorState extends State<_ProcessorNameEditor> {
  late TextEditingController _nameController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.processor.id);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onFocused();
    } else {
      _onNameSubmitted();
    }
  }

  void _onNameSubmitted() {
    final newName = _nameController.text.trim();
    widget.onNameChanged(newName);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      controller: _nameController,
      autofocus: true,
      style: const TextStyle(
        color: Color(0xffffffff),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorStyle: TextStyle(
          color: Color.fromARGB(
            255,
            255,
            231,
            231,
          ),
          fontSize: 12,
          height: 1.5,
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: graphManager.newProcessorNameValidator,
      onFieldSubmitted: (value) {
        _onNameSubmitted();
      },
    );
  }
}

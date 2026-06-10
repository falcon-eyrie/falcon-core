import 'package:falcon_gui/graph_editor/processor_options.dart';
import 'package:falcon_gui/graph_editor/processor_ports.dart';
import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class ProcessorItem extends StatefulWidget {
  const ProcessorItem({
    required this.processor,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onTapDown,
    this.readonly = false,
    super.key,
  });

  final Processor processor;
  final bool readonly;
  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(DragEndDetails)? onPanEnd;
  final void Function()? onTapDown;

  @override
  State<ProcessorItem> createState() => _ProcessorItemState();
}

class _ProcessorItemState extends State<ProcessorItem> {
  // Template processors neither store any state nor they are modifiable
  void _toggleExpanded() {
    graphManager.toggleProcessorExpanded(id: widget.processor.id);
  }

  bool get showPorts => !widget.processor.isTemplate;

  bool get _canExpand => widget.processor.options.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTapDown?.call(),
      child: Container(
        key: ValueKey(widget.processor.id),
        width: 150,
        decoration: BoxDecoration(
          border: Border.all(color: context.c.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(8),
          color: context.c.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              processor: widget.processor,
              readonly: widget.readonly,
              onFocused: () => widget.onTapDown?.call(),
              onPanStart: widget.onPanStart,
              onPanUpdate: widget.onPanUpdate,
              onPanEnd: widget.onPanEnd,
            ),

            _PreventEdit(
              isPreventing: widget.readonly,
              child: ProcessorPortsView(
                processor: widget.processor,
                onExpandToggle: _canExpand ? _toggleExpanded : null,
              ),
            ),
            if (widget.processor.uiMetadata.isExpanded) ...[
              const Divider(),
              _PreventEdit(
                isPreventing: widget.readonly || widget.processor.isTemplate,
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
    required this.readonly,
    required this.processor,
    required this.onFocused,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final Processor processor;
  final VoidCallback onFocused;
  final bool readonly;
  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(DragEndDetails)? onPanEnd;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _isEditing = false;
  bool _isGrabbing = false;

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
    final MouseCursor cursor;
    if (widget.processor.isTemplate) {
      cursor = MouseCursor.defer;
    } else if (_isGrabbing) {
      cursor = SystemMouseCursors.grabbing;
    } else {
      cursor = SystemMouseCursors.grab;
    }
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onPanStart: widget.onPanStart,
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: widget.onPanEnd,
        child: Listener(
          onPointerDown: (event) {
            if (event.buttons == kPrimaryMouseButton) {
              setState(() => _isGrabbing = true);
            }
          },
          onPointerUp: (event) {
            if (event.buttons == 0) {
              setState(() => _isGrabbing = false);
            }
          },
          onPointerCancel: (_) {
            setState(() => _isGrabbing = false);
          },
          child: Container(
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 18,
                  child: Center(
                    child: _isEditing
                        ? _ProcessorNameEditor(
                            processor: widget.processor,
                            onNameChanged: _onNameChanged,
                            onFocused: widget.onFocused,
                          )
                        : _ProcessorName(
                            processorName: widget.processor.id,
                            onClicked: _startEditing,
                            readonly: widget.readonly,
                          ),
                  ),
                ),

                Text(
                  widget.processor.className,
                  style: const TextStyle(
                    color: Color(0xffffffff),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!widget.processor.isTemplate) ...[
                        _PreventEdit(
                          isPreventing: widget.readonly,
                          child: ClickableIcon(
                            icon: const Icon(
                              RemixIcons.delete_bin_2_line,
                              size: 14,
                              color: Color(0xffffffff),
                            ),
                            onPressed: () => graphManager.removeProcessor(
                              id: widget.processor.id,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],

                      _PreventEdit(
                        isPreventing: widget.readonly,
                        child: ClickableIcon(
                          icon: Icon(
                            widget.processor.isTemplate
                                ? RemixIcons.add_line
                                : RemixIcons.file_copy_line,
                            size: 14,
                            color: const Color(0xffffffff),
                          ),
                          onPressed: () => graphManager.duplicateProcessor(
                            processor: widget.processor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessorName extends StatefulWidget {
  const _ProcessorName({
    required this.processorName,
    required this.onClicked,
    required this.readonly,
  });

  final String processorName;
  final bool readonly;
  final VoidCallback onClicked;

  @override
  State<_ProcessorName> createState() => _ProcessorNameState();
}

class _ProcessorNameState extends State<_ProcessorName> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    return _PreventEdit(
      isPreventing: widget.readonly,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        onEnter: (event) => setState(() => _isHovering = true),
        onExit: (event) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: widget.onClicked,
          child: Tooltip(
            message: 'Click to rename',
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: widget.processorName,
                      children: [
                        if (_isHovering) ...[
                          const WidgetSpan(
                            child: SizedBox(width: 4),
                          ),
                          WidgetSpan(
                            child: Icon(
                              RemixIcons.edit_line,
                              size: 14,
                              color: context.c.onPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: const TextStyle(
                      color: Color(0xffffffff),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      textAlign: TextAlign.center,

      style: const TextStyle(
        color: Color(0xffffffff),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.zero,
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

class _PreventEdit extends StatelessWidget {
  const _PreventEdit({
    required this.isPreventing,
    required this.child,
  });
  final Widget child;
  final bool isPreventing;

  @override
  Widget build(BuildContext context) {
    if (!isPreventing) {
      return child;
    }

    return Tooltip(
      message: 'Editing is disabled while pipeline is running',
      child: IgnorePointer(child: child),
    );
  }
}

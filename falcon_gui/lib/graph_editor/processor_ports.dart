import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class ProcessorPortsView extends StatelessWidget {
  const ProcessorPortsView({
    required this.processor,
    required this.isExpanded,
    required this.onExpandToggle,
    super.key,
  });

  final Processor processor;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  @override
  Widget build(BuildContext context) {
    final inPorts = processor.ports.where((port) => port.isIn);
    final outPorts = processor.ports.where((port) => port.isOut);
    return Stack(
      children: [
        IgnorePointer(
          ignoring: processor.isTemplate,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final port in inPorts)
                    _PortRow(
                      processor: processor,
                      port: port,
                    ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final port in outPorts)
                    _PortRow(
                      processor: processor,
                      port: port,
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Center(
            child: GestureDetector(
              onTap: onExpandToggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: isExpanded ? 'Collapse Options' : 'Expand Options',
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      right: 8,
                      left: 8,
                    ),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PortRow extends StatefulWidget {
  const _PortRow({
    required this.processor,
    required this.port,
  });

  final Processor processor;
  final Port port;

  @override
  State<_PortRow> createState() => _PortRowState();
}

class _PortRowState extends State<_PortRow> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    final portSelectionStatus = graphManager.getPortSelectabilityStatus(
      processorId: widget.processor.id,
      portName: widget.port.name,
    );

    final isEnabled =
        portSelectionStatus == PortSelectabilityStatus.selectedAsInput ||
        portSelectionStatus == PortSelectabilityStatus.compatible ||
        portSelectionStatus == PortSelectabilityStatus.idle ||
        portSelectionStatus == PortSelectabilityStatus.connectedIdle;

    final tooltipMessage = switch (portSelectionStatus) {
      PortSelectabilityStatus.idle => 'Click once to start a connection',
      PortSelectabilityStatus.connectedIdle =>
        'Click once to start a connection',
      PortSelectabilityStatus.compatible => 'Click to create a connection',
      PortSelectabilityStatus.alreadyConnected => 'Connection already exists',
      PortSelectabilityStatus.selectedAsInput => 'Cannot connect to self',
      PortSelectabilityStatus.typeIncompatible => 'Incompatible port type',
      PortSelectabilityStatus.bothInput => 'Cannot connect two input ports',
      PortSelectabilityStatus.bothOutput => 'Cannot connect two output ports',
      PortSelectabilityStatus.sameProcessor =>
        'Cannot connect ports within the same processor',
      null => null,
    };

    final text = Column(
      crossAxisAlignment: widget.port.isIn
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.port.name,
          style: TextStyle(
            color: isEnabled ? context.c.onSurface : Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Text(
          widget.port.type,
          style: TextStyle(
            color: isEnabled ? context.c.onSurface.withAlpha(200) : Colors.grey,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    final dot = _PortHalfDot(
      processorId: widget.processor.id,
      portName: widget.port.name,
      isIn: widget.port.isIn,
      isEnabled: isEnabled,
      isTemplate: widget.processor.isTemplate,
      showFullDot:
          !widget.processor.isTemplate &&
          (portSelectionStatus == PortSelectabilityStatus.connectedIdle ||
              portSelectionStatus == PortSelectabilityStatus.selectedAsInput ||
              _isHovering),
    );

    void onPortTouched() {
      if (isEnabled) {
        graphManager.onPortClicked(
          processorId: widget.processor.id,
          port: widget.port,
        );
      }
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) => onPortTouched(),
        onVerticalDragStart: (_) {},
        onVerticalDragUpdate: (_) {},
        onHorizontalDragStart: (_) {},
        onHorizontalDragUpdate: (_) {},
        onHorizontalDragCancel: () {},
        onHorizontalDragEnd: (_) {},
        onHorizontalDragDown: (_) {},
        onVerticalDragCancel: () {},
        onVerticalDragEnd: (_) {},
        onVerticalDragDown: (_) {},
        child: Tooltip(
          mouseCursor: isEnabled
              ? SystemMouseCursors.alias
              : SystemMouseCursors.forbidden,
          message: widget.processor.isTemplate ? '' : tooltipMessage,
          verticalOffset: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.port.isIn
                  ? [dot, const SizedBox(width: 4), text]
                  : [text, const SizedBox(width: 4), dot],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortHalfDot extends StatelessWidget {
  const _PortHalfDot({
    required this.isTemplate,
    required this.processorId,
    required this.portName,
    required this.isIn,
    required this.isEnabled,
    required this.showFullDot,
  });

  final String processorId;
  final String portName;
  final bool isIn;
  final bool isEnabled;
  final bool isTemplate;
  final bool showFullDot;

  void _reportPosition(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    // Get the dot's center position relative to itself
    final dotLocalCenter = renderBox.size.center(Offset.zero);

    // Convert to global coordinates
    final globalPos = renderBox.localToGlobal(dotLocalCenter);

    // Find the ProcessorItem's render box by looking for the ValueKey
    RenderBox? processorItemRenderBox;
    context.visitAncestorElements((element) {
      if (element.widget.key is ValueKey &&
          (element.widget.key as ValueKey<String>?)?.value == processorId) {
        final renderObj = element.renderObject;
        if (renderObj is RenderBox) {
          processorItemRenderBox = renderObj;
          return false; // Stop searching
        }
      }
      return true; // Continue searching
    });

    if (processorItemRenderBox != null) {
      // Convert global position to ProcessorItem's local coordinates
      final localOffset = processorItemRenderBox!.globalToLocal(globalPos);

      graphManager.onPortPositionUpdated(
        processorId: processorId,
        portName: portName,
        newPosition: localOffset,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isTemplate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reportPosition(context);
      });
    }
    // if connected, show full , otherwise border without inside

    final decoration = BoxDecoration(
      color: showFullDot
          ? (isEnabled
                ? (isIn ? Colors.blueAccent : Colors.greenAccent)
                : Colors.grey)
          : null,
      shape: BoxShape.circle,
      border: showFullDot
          ? null
          : Border.all(
              color: isEnabled
                  ? (isIn ? Colors.blueAccent : Colors.greenAccent)
                  : Colors.grey,
              width: 2,
            ),
    );
    return MouseRegion(
      onHover: (event) {},
      child: ClipRect(
        child: Align(
          alignment: isIn ? Alignment.centerRight : Alignment.centerLeft,
          widthFactor: 0.5,
          child: Container(
            width: isEnabled ? 16 : 12,
            height: isEnabled ? 16 : 12,
            decoration: decoration,
          ),
        ),
      ),
    );
  }
}

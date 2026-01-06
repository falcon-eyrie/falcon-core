import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class ProcessorPortsView extends StatelessWidget {
  const ProcessorPortsView({required this.processor, super.key});

  final Processor processor;

  @override
  Widget build(BuildContext context) {
    final inPorts = processor.ports.where((port) => port.isIn);
    final outPorts = processor.ports.where((port) => port.isOut);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }
}

class _PortRow extends StatelessWidget {
  const _PortRow({
    required this.processor,
    required this.port,
  });

  final Processor processor;
  final Port port;

  @override
  Widget build(BuildContext context) {
    final portSelectionStatus = graphManager.getPortSelectabilityStatus(
      processorId: processor.id,
      portName: port.name,
    );

    final isEnabled =
        portSelectionStatus == PortSelectabilityStatus.compatible ||
        portSelectionStatus == PortSelectabilityStatus.idle;

    final tooltipMessage = switch (portSelectionStatus) {
      PortSelectabilityStatus.idle => 'Click to start a connection',
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
      crossAxisAlignment: port.isIn
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          port.name,
          style: TextStyle(
            color: isEnabled ? context.c.onSurface : Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Text(
          port.type,
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
      processorId: processor.id,
      portName: port.name,
      isIn: port.isIn,
      isEnabled: isEnabled,
      isTemplate: processor.isTemplate,
    );

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) => graphManager.onPortClicked(
              processorId: processor.id,
              port: port,
            )
          : null,
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
        message: processor.isTemplate ? '' : tooltipMessage,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: port.isIn
                ? [dot, const SizedBox(width: 4), text]
                : [text, const SizedBox(width: 4), dot],
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
  });

  final String processorId;
  final String portName;
  final bool isIn;
  final bool isEnabled;
  final bool isTemplate;

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

    return ClipRect(
      child: Align(
        alignment: isIn ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: 0.5,
        child: Container(
          width: isEnabled ? 16 : 12,
          height: isEnabled ? 16 : 12,
          decoration: BoxDecoration(
            color: !isEnabled
                ? Colors.grey
                : isIn
                ? Colors.green
                : Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

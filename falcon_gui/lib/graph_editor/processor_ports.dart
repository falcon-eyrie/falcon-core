import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class ProcessorPortsView extends StatelessWidget {
  const ProcessorPortsView({required this.processor, super.key});

  final Processor processor;

  @override
  Widget build(BuildContext context) {
    final srcPorts = processor.ports.where((port) => port.isSrc);
    final dstPorts = processor.ports.where((port) => port.isDst);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final port in dstPorts)
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
              for (final port in srcPorts)
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
    final isEnabled = graphManager.isPortEnabled(
      processorId: processor.id,
      portName: port.name,
    );

    final text = Text(
      port.name,
      style: TextStyle(
        color: isEnabled ? context.c.onSurface : Colors.grey,
      ),
    );

    final dot = _ProcessorPortDot(
      processorId: processor.id,
      portName: port.name,
      isSrc: port.isSrc,
      isEnabled: isEnabled,
      isTemplate: processor.isTemplate,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.alias,
      child: GestureDetector(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: port.isSrc
                ? [dot, const SizedBox(width: 4), text]
                : [text, const SizedBox(width: 4), dot],
          ),
        ),
      ),
    );
  }
}

class _ProcessorPortDot extends StatelessWidget {
  const _ProcessorPortDot({
    required this.isTemplate,
    required this.processorId,
    required this.portName,
    required this.isSrc,
    required this.isEnabled,
  });

  final String processorId;
  final String portName;
  final bool isSrc;
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

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: !isEnabled
            ? Colors.grey
            : isSrc
            ? Colors.blue
            : Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

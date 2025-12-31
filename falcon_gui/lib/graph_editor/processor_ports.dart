import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class ProcessorPortsView extends StatelessWidget {
  const ProcessorPortsView({required this.processor, super.key});

  final Processor processor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final port in processor.inputPorts)
                _PortRow(
                  processor: processor,
                  port: port,
                  isInput: true,
                ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final port in processor.outputPorts)
                _PortRow(
                  processor: processor,
                  port: port,
                  isInput: false,
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
    required this.isInput,
  });

  final Processor processor;
  final Port port;
  final bool isInput;

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
      isInput: isInput,
      isEnabled: isEnabled,
      isTemplate: processor.isTemplate,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.alias,
      child: GestureDetector(
        onTapDown: (_) => graphManager.onPortClicked(
          processorId: processor.id,
          portName: port.name,
        ),
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
            children: isInput
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
    required this.isInput,
    required this.isEnabled,
  });

  final String processorId;
  final String portName;
  final bool isInput;
  final bool isEnabled;
  final bool isTemplate;

  void _reportPosition(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.globalToLocal(
      renderBox.size.center(Offset.zero),
    );

    graphManager.onPortPositionUpdated(
      processorId: processorId,
      portName: portName,
      newPosition: position,
    );
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
            : isInput
            ? Colors.blue
            : Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

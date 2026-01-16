import 'dart:async';

import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({
    required this.isLogsCollapsed,
    required this.onLogsPanelClicked,
    required this.isYamlEditorCollapsed,
    required this.onYamlEditorClicked,
    super.key,
  });
  final bool isLogsCollapsed;
  final bool isYamlEditorCollapsed;
  final VoidCallback onYamlEditorClicked;
  final VoidCallback onLogsPanelClicked;

  @override
  Widget build(BuildContext context) {
    return MultiListener(
      builder: (context) {
        return Container(
          height: 24,
          color: context.c.surfaceContainer,
          child: Row(
            children: [
              const Spacer(),

              _StatusBarButton(
                icon: RemixIcons.list_unordered,
                hasError: falconManager.isLastLogAnError,
                tooltip: isLogsCollapsed
                    ? 'Show Logs Panel'
                    : 'Hide Logs Panel',
                onPressed: onLogsPanelClicked,
                isActive: !isLogsCollapsed,
              ),
              _StatusBarButton(
                icon: RemixIcons.code_block,
                tooltip: isYamlEditorCollapsed
                    ? 'Show YAML Editor'
                    : 'Hide YAML Editor',
                onPressed: onYamlEditorClicked,
                isActive: !isYamlEditorCollapsed,
              ),
              const SizedBox(width: 8),
              _FalconStateIndicator(falconState: falconManager.falconState),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBarButton extends StatelessWidget {
  const _StatusBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isActive,
    this.hasError = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            color: isActive ? context.c.onPrimary : null,
            width: 32,
            height: 24,
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    size: 18,
                  ),
                ),

                if (hasError) ...[
                  const Align(
                    alignment: Alignment.topLeft,
                    child: _BlinkingErrorIcon(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlinkingErrorIcon extends StatefulWidget {
  const _BlinkingErrorIcon();

  @override
  State<_BlinkingErrorIcon> createState() => _BlinkingErrorIconState();
}

class _BlinkingErrorIconState extends State<_BlinkingErrorIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(_controller),
      child: const Icon(
        RemixIcons.error_warning_fill,
        color: Colors.red,
        size: 12,
      ),
    );
  }
}

class _FalconStateIndicator extends StatelessWidget {
  const _FalconStateIndicator({required this.falconState});

  final FalconState falconState;

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(falconState);
    return Tooltip(
      message: _stateExplanation(falconState),
      child: Row(
        children: [
          Icon(
            RemixIcons.circle_fill,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            falconState.toString(),
            style: TextStyle(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Color _stateColor(FalconState falconState) => switch (falconState) {
  FalconState.unknown => Colors.grey,
  FalconState.ready => Colors.blue,
  FalconState.processing => Colors.green,
  FalconState.noGraph => Colors.orange,
  FalconState.constructing => Colors.purple,
  FalconState.preparing => Colors.indigo,
  FalconState.stopping => Colors.red,
  FalconState.error => Colors.redAccent,
  FalconState.starting => Colors.blueAccent,
};

String _stateExplanation(FalconState falconState) => switch (falconState) {
  FalconState.ready =>
    'Processing pipeline is constructed from the graph. '
        'Falcon is ready to process data.',
  FalconState.processing => 'Falcon is currently processing data.',
  FalconState.noGraph =>
    'No graph is loaded in falcon. Please load a graph to proceed.',
  FalconState.constructing =>
    'Falcon is constructing processing pipeline from the graph. Please wait.',
  FalconState.preparing =>
    'Falcon is preparing the pipeline to start processing. Please wait.',
  FalconState.stopping =>
    'Falcon is stopping the current processing pipeline. Please wait.',
  FalconState.error =>
    'Falcon has encountered an error. Please check the logs for more details.',
  FalconState.starting =>
    'Falcon is starting the processing pipeline. Please wait.',
  FalconState.unknown =>
    'Falcon state is unknown. '
        'This is likely caused by falcon instance not running.',
};

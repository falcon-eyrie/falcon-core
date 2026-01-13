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
    super.key,
  });
  final bool isLogsCollapsed;
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
              Container(
                color: isLogsCollapsed ? null : context.c.onPrimary,
                width: 32,
                height: 24,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onLogsPanelClicked,
                    child: Tooltip(
                      message: isLogsCollapsed
                          ? 'Show Logs Panel'
                          : 'Hide Logs Panel',
                      child: const Icon(RemixIcons.list_view, size: 18),
                    ),
                  ),
                ),
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
            Icons.circle,
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

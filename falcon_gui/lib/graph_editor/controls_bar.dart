import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/settings/settings_view.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class ControlsBar extends StatelessWidget {
  const ControlsBar({
    required this.onProcessorPanelClicked,
    required this.isProcessorsCollapsed,
    super.key,
  });
  final bool isProcessorsCollapsed;
  final VoidCallback onProcessorPanelClicked;

  @override
  Widget build(BuildContext context) {
    return MultiListener(
      builder: (context) {
        return Container(
          color: context.c.surfaceContainer,
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(RemixIcons.flow_chart),
                style: IconButton.styleFrom(
                  backgroundColor: isProcessorsCollapsed
                      ? null
                      : context.c.primary,
                  foregroundColor: isProcessorsCollapsed
                      ? null
                      : context.c.onPrimary,
                ),
                tooltip: isProcessorsCollapsed
                    ? 'Show Processors Panel'
                    : 'Hide Processors Panel',
                onPressed: onProcessorPanelClicked,
              ),

              const Spacer(),
              const IconButton(
                icon: Icon(RemixIcons.arrow_go_back_line),
                tooltip: 'Undo',
                onPressed: null,
              ),
              const SizedBox(width: 8),
              const IconButton(
                icon: Icon(RemixIcons.arrow_go_forward_line),
                tooltip: 'Redo',
                onPressed: null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  graphManager.isAllCollapsed
                      ? Remix.arrow_down_double_line
                      : Remix.arrow_down_double_line,
                ),
                tooltip: 'Toggle collapse all',
                onPressed: graphManager.toggleCollapseAll,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(RemixIcons.contract_left_right_line),
                tooltip: 'Reset zoom',
                onPressed: graphManager.resetZoom,
              ),
              IconButton(
                icon: const Icon(RemixIcons.zoom_out_line),
                tooltip: 'Zoom out',
                onPressed: graphManager.zoomOut,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(RemixIcons.zoom_in_line),
                tooltip: 'Zoom in',
                onPressed: graphManager.zoomIn,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  falconManager.falconState == FalconState.processing
                      ? RemixIcons.stop_line
                      : RemixIcons.play_line,
                ),
                tooltip: falconManager.falconState == FalconState.processing
                    ? 'Stop Pipeline'
                    : 'Run Pipeline',
                onPressed:
                    falconManager.falconState == FalconState.ready ||
                        falconManager.falconState == FalconState.processing
                    ? falconManager.toggleProcessingState
                    : null,
              ),
              const SizedBox(width: 8),

              IconButton(
                icon: const Icon(RemixIcons.settings_3_line),
                tooltip: 'Settings',
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const SettingsView(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

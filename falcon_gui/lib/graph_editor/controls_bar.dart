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
    required this.onYamlPanelClicked,
    required this.isYamlCollapsed,
    required this.isProcessorsCollapsed,
    super.key,
  });
  final bool isProcessorsCollapsed;
  final bool isYamlCollapsed;
  final VoidCallback onYamlPanelClicked;
  final VoidCallback onProcessorPanelClicked;

  @override
  Widget build(BuildContext context) {
    return MultiListener(
      builder: (context) {
        return ColoredBox(
          color: context.c.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.account_tree),
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
                const SizedBox(width: 8),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.code),
                  style: IconButton.styleFrom(
                    backgroundColor: isYamlCollapsed ? null : context.c.primary,
                    foregroundColor: isYamlCollapsed
                        ? null
                        : context.c.onPrimary,
                  ),
                  tooltip: isYamlCollapsed
                      ? 'Show YAML Panel'
                      : 'Hide YAML Panel',
                  onPressed: onYamlPanelClicked,
                ),

                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: () {
                    debugPrint('Undo pressed');
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo',
                  onPressed: () {
                    debugPrint('Redo pressed');
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    graphManager.isAllCollapsed
                        ? Remix.arrow_down_double_fill
                        : Remix.arrow_up_double_fill,
                  ),
                  tooltip: 'Toggle collapse all',
                  onPressed: graphManager.toggleCollapseAll,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.zoom_in_map),
                  tooltip: 'Reset zoom',
                  onPressed: graphManager.resetZoom,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  tooltip: 'Zoom out',
                  onPressed: graphManager.zoomOut,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  tooltip: 'Zoom in',
                  onPressed: graphManager.zoomIn,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    falconManager.falconState == FalconState.processing
                        ? Icons.stop
                        : Icons.play_arrow,
                  ),
                  tooltip: 'Run Pipeline',
                  onPressed:
                      falconManager.falconState == FalconState.ready ||
                          falconManager.falconState == FalconState.processing
                      ? falconManager.toggleProcessingState
                      : null,
                ),
                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.settings),
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
          ),
        );
      },
    );
  }
}

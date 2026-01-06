import 'package:falcon_gui/settings/settings_view.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/falcon_state.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';

class GraphToolbar extends StatelessWidget {
  const GraphToolbar({
    required this.onProcessorPanelClicked,
    required this.onYamlPanelClicked,
    required this.isYamlCollapsed,
    required this.isProcessorsCollapsed,
    super.key,
  });
  final VoidCallback onProcessorPanelClicked;
  final bool isYamlCollapsed;
  final bool isProcessorsCollapsed;
  final VoidCallback onYamlPanelClicked;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: falconManager,
      builder: (context, child) {
        return ColoredBox(
          color: context.c.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
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
                const SizedBox(width: 20),

                // alter background color when panel is visible
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
                if (falconManager.falconState == FalconState.ready) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.play_arrow,
                    ),
                    tooltip: 'Run Pipeline',
                    onPressed: falconManager.toggleProcessingState,
                  ),
                ] else if (falconManager.falconState ==
                    FalconState.processing) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.stop,
                    ),
                    tooltip: 'Stop Pipeline',
                    onPressed: falconManager.toggleProcessingState,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:falcon_gui/graph_editor/processors_panel.dart';
import 'package:falcon_gui/model/falcon_state.dart';
import 'package:falcon_gui/settings/settings_view.dart';
import 'package:falcon_gui/state/falcon_manager.dart';
import 'package:falcon_gui/state/graph_manager.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class ControlsBar extends StatelessWidget {
  const ControlsBar({
    required this.activeCategory,
    required this.onProcessorCategoryHovered,
    required this.onLiveViewToggled,
    super.key,
  });
  final ActiveProcessorCategory? activeCategory;
  final ValueChanged<ActiveProcessorCategory?> onProcessorCategoryHovered;
  final VoidCallback onLiveViewToggled;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([falconManager, graphManager]),
      builder: (context, _) {
        return Container(
          color: context.c.surfaceContainer,
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(RemixIcons.folder_open_line),
                tooltip: 'Load Graph File',
                onPressed: falconManager.openFile,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(RemixIcons.file_add_line),
                tooltip: 'Create a New Graph File',
                onPressed: falconManager.newFile,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(RemixIcons.export_line),
                tooltip: 'Save Graph File As',
                onPressed: falconManager.currentGraphFile != null
                    ? falconManager.saveGraphAs
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
              const Spacer(),

              Row(
                children: [
                  _ProcessorPanelButton(
                    isActive: activeCategory == ActiveProcessorCategory.sources,
                    onMouseEnter: () => onProcessorCategoryHovered(
                      ActiveProcessorCategory.sources,
                    ),
                    icon: RemixIcons.guide_line,
                    label: 'Sources',
                  ),
                  const SizedBox(width: 8),
                  _ProcessorPanelButton(
                    isActive:
                        activeCategory == ActiveProcessorCategory.intermediates,
                    onMouseEnter: () => onProcessorCategoryHovered(
                      ActiveProcessorCategory.intermediates,
                    ),
                    icon: RemixIcons.exchange_2_line,
                    label: 'Intermediates',
                  ),
                  const SizedBox(width: 8),
                  _ProcessorPanelButton(
                    isActive: activeCategory == ActiveProcessorCategory.sinks,
                    onMouseEnter: () => onProcessorCategoryHovered(
                      ActiveProcessorCategory.sinks,
                    ),
                    icon: RemixIcons.record_circle_line,
                    label: 'Sinks',
                  ),
                ],
              ),

              const Spacer(),
              IconButton(
                icon: const Icon(RemixIcons.pulse_fill),
                tooltip: 'Live View',
                onPressed: onLiveViewToggled,
              ),
              const SizedBox(width: 8),
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
                      : Remix.arrow_up_double_line,
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
                icon: switch (falconManager.falconState) {
                  FalconState.processing => const Icon(RemixIcons.stop_line),
                  FalconState.starting => const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  FalconState.stopping => const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),

                  _ => const Icon(RemixIcons.play_line),
                },
                tooltip: switch (falconManager.falconState) {
                  FalconState.processing => 'Stop Processing',
                  FalconState.ready => 'Start Processing',
                  _ => null,
                },
                onPressed: switch (falconManager.falconState) {
                  FalconState.processing => falconManager.toggleProcessingState,
                  FalconState.ready => falconManager.toggleProcessingState,
                  _ => null,
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ProcessorPanelButton extends StatelessWidget {
  const _ProcessorPanelButton({
    required this.isActive,
    required this.onMouseEnter,
    required this.icon,
    required this.label,
  });
  final bool isActive;
  final VoidCallback onMouseEnter;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onMouseEnter(),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? context.c.primary : null,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? context.c.onPrimary : null,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? context.c.onPrimary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

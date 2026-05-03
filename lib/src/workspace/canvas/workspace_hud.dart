import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/workspace/canvas/workspace_chrome_view_model.dart';

@immutable
class WorkspaceHudActions {
  const WorkspaceHudActions({
    required this.onToggleExpose,
    required this.onFitWorkspaceViewportToContent,
    required this.onConfirmCollateWorkspaceWindows,
    required this.onConfirmApplyExposeGridToWorkspace,
    required this.onOpenWorkspaceLinks,
    required this.onClearExposeSelection,
    required this.onSetWorkspaceZoom,
    required this.onRefreshActiveWorkspaceThumbnail,
  });

  final VoidCallback onToggleExpose;
  final VoidCallback onFitWorkspaceViewportToContent;
  final Future<void> Function() onConfirmCollateWorkspaceWindows;
  final Future<void> Function() onConfirmApplyExposeGridToWorkspace;
  final Future<void> Function() onOpenWorkspaceLinks;
  final VoidCallback onClearExposeSelection;
  final void Function(String workspaceId, double zoom) onSetWorkspaceZoom;
  final Future<void> Function() onRefreshActiveWorkspaceThumbnail;
}

class WorkspaceHud extends StatelessWidget {
  const WorkspaceHud({super.key, required this.viewModel, required this.actions});

  static const double gap = 10;

  final WorkspaceChromeViewModel viewModel;
  final WorkspaceHudActions actions;

  Widget _buildHudAction({required String tooltip, required VoidCallback? onTap, required Widget child}) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.white.withValues(alpha: 0.52),
            child: InkWell(onTap: onTap, child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceZoomControl(BuildContext context) {
    final zoomValue = _workspaceZoomSliderValue(viewModel.workspaceZoom);

    return Tooltip(
      message: 'Workspace zoom',
      waitDuration: const Duration(milliseconds: 350),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 170,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(Icons.remove_rounded, size: 14, color: AppTheme.textMuted.withValues(alpha: 0.9)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppTheme.textPrimary,
                      inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.18),
                      thumbColor: AppTheme.textPrimary,
                      overlayColor: AppTheme.textPrimary.withValues(alpha: 0.14),
                    ),
                    child: Slider(
                      value: zoomValue,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        actions.onSetWorkspaceZoom(viewModel.workspaceId, _workspaceZoomForSliderValue(value));
                      },
                      onChangeEnd: (_) => unawaited(actions.onRefreshActiveWorkspaceThumbnail()),
                    ),
                  ),
                ),
                Icon(Icons.add_rounded, size: 14, color: AppTheme.textMuted.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _workspaceZoomSliderValue(double zoom) {
    final safeZoom = zoom.clamp(workspaceMinZoom, workspaceMaxZoom);
    final minLog = math.log(workspaceMinZoom);
    final maxLog = math.log(workspaceMaxZoom);
    final zoomLog = math.log(safeZoom);
    return (zoomLog - minLog) / (maxLog - minLog);
  }

  double _workspaceZoomForSliderValue(double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    final minLog = math.log(workspaceMinZoom);
    final maxLog = math.log(workspaceMaxZoom);
    final zoomLog = minLog + ((maxLog - minLog) * clampedValue);
    return math.exp(zoomLog);
  }

  @override
  Widget build(BuildContext context) {
    final modeActions = <Widget>[
      if (!viewModel.isExposeMode) ...[
        _buildHudAction(
          tooltip: 'Zoom to fit',
          onTap: actions.onFitWorkspaceViewportToContent,
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.fit_screen_rounded, size: 17, color: AppTheme.textPrimary),
          ),
        ),
        _buildHudAction(
          tooltip: 'Collate',
          onTap: () => unawaited(actions.onConfirmCollateWorkspaceWindows()),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.gps_fixed_rounded, size: 18, color: AppTheme.textPrimary),
          ),
        ),
        _buildWorkspaceZoomControl(context),
      ] else
        _buildHudAction(
          tooltip: 'Apply grid to freeform',
          onTap: () => unawaited(actions.onConfirmApplyExposeGridToWorkspace()),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.task_alt_rounded, size: 18, color: AppTheme.textPrimary),
          ),
        ),
      _buildHudAction(
        tooltip: 'Links',
        onTap: () => unawaited(actions.onOpenWorkspaceLinks()),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.menu_rounded, size: 18, color: AppTheme.textPrimary),
        ),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHudAction(
          tooltip: viewModel.isExposeMode ? 'Freeform' : 'Expose',
          onTap: actions.onToggleExpose,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              viewModel.isExposeMode ? Icons.grid_view_rounded : Icons.apps_rounded,
              size: 17,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: gap),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppTheme.textMuted, height: 1.1),
                child: Text('${viewModel.imageLabel} · ${viewModel.videoLabel} · ${viewModel.linkLabel}'),
              ),
            ),
          ),
        ),
        const SizedBox(width: gap),
        for (var i = 0; i < modeActions.length; i++) ...[if (i > 0) const SizedBox(width: gap), modeActions[i]],
        if (viewModel.showExposeSelectionHud) ...[
          const SizedBox(width: gap),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(minHeight: 38),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppTheme.textMuted, height: 1.1),
                        child: Text('${viewModel.selectedCount} selected'),
                      ),
                      const SizedBox(width: 8),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppTheme.textMuted, height: 1.1),
                        child: const Text('·'),
                      ),
                      const SizedBox(width: 8),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppTheme.textMuted, height: 1.1),
                        child: const Text('Click workspace to move'),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: actions.onClearExposeSelection,
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

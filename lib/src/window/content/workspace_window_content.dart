import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/window/content/asset_content.dart';
import 'package:serenity_viewer/src/window/content/asset_preview_transforms.dart';
import 'package:serenity_viewer/src/window/interaction/window_zoom_update.dart';
import 'package:serenity_viewer/src/window/presentation/workspace_window_view_model.dart';

class WorkspaceWindowContent extends StatelessWidget {
  const WorkspaceWindowContent({
    super.key,
    required this.viewModel,
    required this.showControls,
    required this.showPausedPlaybackButton,
    required this.shrinkContent,
    required this.inset,
    required this.onTap,
    required this.onZoomChanged,
    required this.onIntrinsicSizeResolved,
    required this.onTogglePlayback,
    required this.onVideoControlInteractionChanged,
    required this.onVideoPositionChanged,
    required this.onCycleVideoPlaybackSpeed,
  });

  final WorkspaceWindowViewModel viewModel;
  final bool showControls;
  final bool showPausedPlaybackButton;
  final bool shrinkContent;
  final double inset;
  final VoidCallback onTap;
  final ValueChanged<WindowZoomUpdate> onZoomChanged;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final ValueChanged<int?> onTogglePlayback;
  final ValueChanged<bool> onVideoControlInteractionChanged;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;

  double _hoverPreviewScale() {
    if (!shrinkContent) {
      return 1.0;
    }
    return assetPreviewScaleForInset(viewModel.window, inset);
  }

  Window _windowForHoverPreview() {
    final scale = _hoverPreviewScale();
    return scaleAssetPreviewWindow(viewModel.window, scale);
  }

  WindowZoomUpdate _zoomUpdateForWindowState(WindowZoomUpdate update) {
    return remapWindowZoomUpdateForPreviewScale(update, _hoverPreviewScale());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AssetContent(
          key: ValueKey(viewModel.window.asset.id),
          window: _windowForHoverPreview(),
          isLoaded: viewModel.isLoaded,
          sharedVideoController: viewModel.sharedVideoController,
          sharedVideoInitialization: viewModel.sharedVideoInitialization,
          onTap: onTap,
          onZoomChanged: (update) => onZoomChanged(_zoomUpdateForWindowState(update)),
          onIntrinsicSizeResolved: onIntrinsicSizeResolved,
          isVideoPaused: viewModel.isVideoPaused,
          onTogglePlayback: onTogglePlayback,
          showControls: showControls,
          showPausedPlaybackButton: showPausedPlaybackButton,
          workspaceZoom: viewModel.workspaceZoom,
          onVideoControlInteractionChanged: onVideoControlInteractionChanged,
          onVideoPositionChanged: onVideoPositionChanged,
          onCycleVideoPlaybackSpeed: onCycleVideoPlaybackSpeed,
          allowDirectContentGestures: viewModel.areControlsPinned,
        ),
      ),
    );
  }
}

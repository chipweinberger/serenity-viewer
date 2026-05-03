import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/asset_window/content/asset_content.dart';
import 'package:serenity_viewer/src/asset_window/content/asset_preview_transforms.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/asset_window/presentation/asset_window_view_model.dart';

class AssetWindowContent extends StatelessWidget {
  const AssetWindowContent({
    super.key,
    required this.viewModel,
    required this.showExpandedVideoControls,
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

  final AssetWindowViewModel viewModel;
  final bool showExpandedVideoControls;
  final bool shrinkContent;
  final double inset;
  final VoidCallback onTap;
  final ValueChanged<AssetWindowZoomUpdate> onZoomChanged;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final VoidCallback onTogglePlayback;
  final ValueChanged<bool> onVideoControlInteractionChanged;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;

  double _hoverPreviewScale() {
    if (!shrinkContent) {
      return 1.0;
    }
    return assetPreviewScaleForInset(viewModel.window, inset);
  }

  WorkspaceWindowState _windowForHoverPreview() {
    final scale = _hoverPreviewScale();
    return scaleAssetPreviewWindow(viewModel.window, scale);
  }

  AssetWindowZoomUpdate _zoomUpdateForWindowState(AssetWindowZoomUpdate update) {
    return remapAssetWindowZoomUpdateForPreviewScale(update, _hoverPreviewScale());
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
          showVideoControls: true,
          showExpandedVideoControls: showExpandedVideoControls,
          workspaceZoom: viewModel.workspaceZoom,
          onVideoControlInteractionChanged: onVideoControlInteractionChanged,
          onVideoPositionChanged: onVideoPositionChanged,
          onCycleVideoPlaybackSpeed: onCycleVideoPlaybackSpeed,
          allowDirectContentGestures: viewModel.isPinnedHover,
        ),
      ),
    );
  }
}

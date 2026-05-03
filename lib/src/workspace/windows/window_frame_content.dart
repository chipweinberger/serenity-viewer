import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/workspace/windows/workspace_window_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_frame_view_model.dart';
import 'package:serenity_viewer/src/workspace/windows/window_zoom_update.dart';
import 'package:serenity_viewer/src/media/assets/media_canvas.dart';
import 'package:serenity_viewer/src/media/assets/media_preview_transforms.dart';

class WindowFrameContent extends StatelessWidget {
  const WindowFrameContent({
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

  final WindowFrameViewModel viewModel;
  final bool showExpandedVideoControls;
  final bool shrinkContent;
  final double inset;
  final VoidCallback onTap;
  final ValueChanged<WindowZoomUpdate> onZoomChanged;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final VoidCallback onTogglePlayback;
  final ValueChanged<bool> onVideoControlInteractionChanged;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;

  double _hoverPreviewScale() {
    if (!shrinkContent) {
      return 1.0;
    }
    return previewWindowScaleForInset(viewModel.window, inset);
  }

  WorkspaceWindowState _windowForHoverPreview() {
    final scale = _hoverPreviewScale();
    return scalePreviewWindow(viewModel.window, scale);
  }

  WindowZoomUpdate _zoomUpdateForWindowState(WindowZoomUpdate update) {
    return remapWindowZoomUpdateForPreviewScale(update, _hoverPreviewScale());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MediaCanvas(
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

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/models/asset_window_state.dart';
import 'package:serenity_viewer/src/models/window_zoom_update.dart';
import 'package:serenity_viewer/src/widgets/serenity_media_canvas.dart';
import 'package:serenity_viewer/src/widgets/serenity_media_preview_transforms.dart';

class SerenityWindowFrameContent extends StatelessWidget {
  const SerenityWindowFrameContent({
    super.key,
    required this.window,
    required this.isLoaded,
    required this.sharedVideoController,
    required this.sharedVideoInitialization,
    required this.isPinnedHover,
    required this.showExpandedVideoControls,
    required this.workspaceZoom,
    required this.shrinkContent,
    required this.inset,
    required this.onTap,
    required this.onZoomChanged,
    required this.onIntrinsicSizeResolved,
    required this.isVideoPaused,
    required this.onTogglePlayback,
    required this.onVideoControlInteractionChanged,
    required this.onVideoPositionChanged,
    required this.onCycleVideoPlaybackSpeed,
  });

  final AssetWindowState window;
  final bool isLoaded;
  final VideoPlayerController? sharedVideoController;
  final Future<void>? sharedVideoInitialization;
  final bool isPinnedHover;
  final bool showExpandedVideoControls;
  final double workspaceZoom;
  final bool shrinkContent;
  final double inset;
  final VoidCallback onTap;
  final ValueChanged<WindowZoomUpdate> onZoomChanged;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final bool isVideoPaused;
  final VoidCallback onTogglePlayback;
  final ValueChanged<bool> onVideoControlInteractionChanged;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;

  double _hoverPreviewScale() {
    if (!shrinkContent) {
      return 1.0;
    }
    return previewWindowScaleForInset(window, inset);
  }

  AssetWindowState _windowForHoverPreview() {
    final scale = _hoverPreviewScale();
    return scalePreviewWindow(window, scale);
  }

  WindowZoomUpdate _zoomUpdateForWindowState(WindowZoomUpdate update) {
    return remapWindowZoomUpdateForPreviewScale(update, _hoverPreviewScale());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SerenityMediaCanvas(
          key: ValueKey(window.asset.id),
          window: _windowForHoverPreview(),
          isLoaded: isLoaded,
          sharedVideoController: sharedVideoController,
          sharedVideoInitialization: sharedVideoInitialization,
          onTap: onTap,
          onZoomChanged: (update) => onZoomChanged(_zoomUpdateForWindowState(update)),
          onIntrinsicSizeResolved: onIntrinsicSizeResolved,
          isVideoPaused: isVideoPaused,
          onTogglePlayback: onTogglePlayback,
          showVideoControls: true,
          showExpandedVideoControls: showExpandedVideoControls,
          workspaceZoom: workspaceZoom,
          onVideoControlInteractionChanged: onVideoControlInteractionChanged,
          onVideoPositionChanged: onVideoPositionChanged,
          onCycleVideoPlaybackSpeed: onCycleVideoPlaybackSpeed,
          allowDirectContentGestures: isPinnedHover,
        ),
      ),
    );
  }
}

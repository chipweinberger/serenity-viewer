import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/environment/window.dart';

@immutable
class WorkspaceWindowViewModel {
  const WorkspaceWindowViewModel({
    required this.window,
    required this.isLoaded,
    required this.sharedVideoController,
    required this.sharedVideoInitialization,
    required this.isFocused,
    required this.isSelected,
    required this.isPinnedHover,
    required this.workspaceZoom,
    required this.flashNonce,
    required this.isVideoPaused,
    required this.isOptionGestureTarget,
  });

  final Window window;
  final bool isLoaded;
  final VideoPlayerController? sharedVideoController;
  final Future<void>? sharedVideoInitialization;
  final bool isFocused;
  final bool isSelected;
  final bool isPinnedHover;
  final double workspaceZoom;
  final int flashNonce;
  final bool isVideoPaused;
  final bool isOptionGestureTarget;
}

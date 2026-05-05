import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_runtime_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_workspace_controller.dart';

class WorkspacePlaybackController {
  WorkspacePlaybackController({
    required this.windowInteractionState,
    required this.replaceWorkspace,
    required this.markDirty,
    required this.currentVideoPositionMs,
    required this.environment,
    required this.activeWorkspaceOrNull,
  }) : runtime = WorkspacePlaybackRuntimeController(windowInteractionState: windowInteractionState),
       workspace = WorkspacePlaybackWorkspaceController(replaceWorkspace: replaceWorkspace);

  final WindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final VoidCallback markDirty;
  final int? Function(String windowId) currentVideoPositionMs;
  final Environment? Function() environment;
  final Workspace? Function() activeWorkspaceOrNull;
  final WorkspacePlaybackRuntimeController runtime;
  final WorkspacePlaybackWorkspaceController workspace;

  void setVideoPosition(String windowId, int positionMs) {
    workspace.setPosition(activeWorkspaceOrNull(), windowId, positionMs);
  }

  void cycleVideoPlaybackSpeed(String windowId) {
    workspace.cycleSpeed(activeWorkspaceOrNull(), windowId);
  }

  bool isVideoWindowPaused(String windowId) {
    return runtime.isPaused(windowId);
  }

  bool anyVideosPlaying() {
    return runtime.anyPlaying(environment());
  }

  void toggleVideoPlayback(String windowId, {int? positionMs}) {
    if (!workspace.canToggle(activeWorkspaceOrNull(), windowId)) {
      return;
    }

    final wasPaused = runtime.isPaused(windowId);
    if (wasPaused) {
      workspace.clearPosition(activeWorkspaceOrNull(), windowId);
    } else {
      final nextPositionMs = currentVideoPositionMs(windowId) ?? positionMs;
      if (nextPositionMs != null) {
        workspace.setPosition(activeWorkspaceOrNull(), windowId, nextPositionMs);
      }
    }

    runtime.toggle(windowId);
    markDirty();
  }

  void pauseAllVideos() {
    final workspaceState = activeWorkspaceOrNull();
    if (workspaceState != null) {
      final currentPositions = <String, int>{};
      for (final window in workspaceState.windows) {
        if (window.asset.type != AssetType.video || runtime.isPaused(window.asset.id)) {
          continue;
        }

        final positionMs = currentVideoPositionMs(window.asset.id);
        if (positionMs != null) {
          currentPositions[window.asset.id] = positionMs;
        }
      }

      workspace.setPositions(workspaceState, currentPositions);
    }

    runtime.stopAll(environment());
  }

  void playAllVideos() {
    runtime.playAll(environment());
  }

  void toggleAllVideos() {
    if (anyVideosPlaying()) {
      pauseAllVideos();
      return;
    }

    playAllVideos();
  }
}

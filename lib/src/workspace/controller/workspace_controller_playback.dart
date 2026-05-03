part of 'workspace_controller.dart';

class WorkspacePlaybackControllerState {
  WorkspacePlaybackControllerState({
    required this.windowInteractionState,
    required this.commitInteractionState,
    required this.replaceWorkspace,
  });

  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;

  void setVideoPosition(Workspace? workspace, String windowId, int positionMs) {
    if (workspace == null) {
      return;
    }

    final currentWindow = workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
    if (currentWindow == null || currentWindow.videoPositionMs == positionMs) {
      return;
    }

    replaceWorkspace(
      WorkspacePlaybackOperations.setVideoPosition(workspace, windowId, positionMs),
      queueThumbnail: false,
    );
  }

  void cycleVideoPlaybackSpeed(Workspace? workspace, String windowId) {
    if (workspace == null ||
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isEmpty) {
      return;
    }

    replaceWorkspace(WorkspacePlaybackOperations.cycleVideoPlaybackSpeed(workspace, windowId), queueThumbnail: false);
  }

  bool isVideoWindowPaused(String windowId) {
    return windowInteractionState.pausedVideoWindows[windowId] ?? true;
  }

  void toggleVideoPlayback(Workspace? workspace, String windowId) {
    if (workspace == null ||
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isEmpty) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.pausedVideoWindows[windowId] =
          !(windowInteractionState.pausedVideoWindows[windowId] ?? true);
    });
  }

  void pauseAllVideos(Environment? environment) {
    if (environment == null) {
      return;
    }

    commitInteractionState(() {
      for (final workspace in environment.workspaces) {
        for (final window in workspace.windows) {
          if (window.asset.type == AssetType.video) {
            windowInteractionState.pausedVideoWindows[window.asset.id] = true;
          }
        }
      }
    });
  }

  void clearRuntimeState(String windowId) {
    windowInteractionState.pausedVideoWindows.remove(windowId);
  }
}

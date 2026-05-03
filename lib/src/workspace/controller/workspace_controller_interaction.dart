part of 'workspace_controller.dart';

class _WorkspaceInteractionController {
  _WorkspaceInteractionController({required this.windowInteractionState, required this.commitInteractionState});

  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;

  void setOptionGestureWindowId(String? windowId) {
    if (windowInteractionState.optionGestureWindowId == windowId) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.optionGestureWindowId = windowId;
    });
  }

  void setPinnedHoverWindow(String? windowId) {
    if (windowInteractionState.pinnedHoverWindowId == windowId) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.pinnedHoverWindowId = windowId;
    });
  }

  void clearPinnedHoverWindow() {
    setPinnedHoverWindow(null);
  }

  void flashWindow(String windowId, {required bool mounted}) {
    windowInteractionState.windowFlashTimer?.cancel();
    commitInteractionState(() {
      windowInteractionState.flashedWindowId = windowId;
      windowInteractionState.windowFlashNonce += 1;
    });
    windowInteractionState.windowFlashTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || windowInteractionState.flashedWindowId != windowId) {
        return;
      }
      commitInteractionState(() {
        windowInteractionState.flashedWindowId = null;
      });
    });
  }

  void toggleExposeWindowSelected(String windowId) {
    commitInteractionState(() {
      if (windowInteractionState.selectedExposeWindowIds.contains(windowId)) {
        windowInteractionState.selectedExposeWindowIds.remove(windowId);
      } else {
        windowInteractionState.selectedExposeWindowIds.add(windowId);
      }
    });
  }

  void clearExposeSelection() {
    if (windowInteractionState.selectedExposeWindowIds.isEmpty) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.selectedExposeWindowIds.clear();
    });
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

  int selectedExposeWindowCount(Workspace workspace) {
    return workspace.windows
        .where((window) => windowInteractionState.selectedExposeWindowIds.contains(window.asset.id))
        .length;
  }

  void removeWindowSelection(String windowId) {
    windowInteractionState.selectedExposeWindowIds.remove(windowId);
  }

  void clearWindowRuntimeState(String windowId) {
    windowInteractionState.pausedVideoWindows.remove(windowId);
  }
}

part of 'workspace_controller.dart';

class WorkspaceWindowControllerState {
  WorkspaceWindowControllerState({
    required this.chromeState,
    required this.commitInteractionState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  });

  final ChromeState chromeState;
  final SerenityWorkspaceCommit commitInteractionState;
  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;

  Window? focusedWindowOrNull(Workspace? workspace) {
    if (workspace == null || workspace.windows.isEmpty) {
      return null;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sortedWindows.last;
  }

  void focusWindow(Workspace workspace, String windowId) {
    final result = WorkspaceStackingOperations.focusWindow(workspace, windowId);
    if (identical(result.workspace, workspace)) {
      return;
    }

    if (result.previousZOrder != null) {
      windowInteractionState.previousWindowZOrders[windowId] = result.previousZOrder!;
    }
    replaceWorkspace(result.workspace, queueThumbnail: true);
  }

  void restorePreviousWindowZOrder(Workspace workspace, String windowId) {
    final previousZ = windowInteractionState.previousWindowZOrders.remove(windowId);
    if (previousZ == null) {
      return;
    }

    replaceWorkspace(
      WorkspaceStackingOperations.restorePreviousWindowZOrder(workspace, windowId, previousZ),
      queueThumbnail: true,
    );
  }

  void moveWindow(Workspace workspace, String windowId, Offset delta) {
    replaceWorkspace(WorkspaceLayout.moveWindow(workspace, windowId, delta), queueThumbnail: true);
  }

  void resizeWindow(Workspace workspace, String windowId, AssetWindowResizeHandle handle, Offset delta) {
    replaceWorkspace(WorkspaceLayout.resizeWindow(workspace, windowId, handle, delta), queueThumbnail: true);
  }

  void transformWindowFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
    replaceWorkspace(
      WorkspaceLayout.transformWindowFromTrackpad(workspace, windowId, scaleDelta),
      queueThumbnail: true,
    );
  }

  void fitWindowToContent(Workspace? workspace, String windowId) {
    if (workspace == null || workspace.windows.every((window) => window.asset.id != windowId)) {
      return;
    }

    replaceWorkspace(WorkspaceLayout.fitWindowToContent(workspace, windowId), queueThumbnail: true);
  }

  void handleOptionGestureHover(
    PointerHoverEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    final targetWindowId = windowInteractionState.activeGestureWindowId;
    if (chromeState.screen != SerenityScreen.workspace ||
        chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose ||
        isCommandPressedForContentGesture ||
        !isOptionPressedForWindowGesture ||
        targetWindowId == null ||
        event.delta == Offset.zero) {
      return;
    }

    moveWindow(workspace, targetWindowId, event.delta / workspace.viewportZoom);
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

  void setWindowZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    replaceWorkspace(WorkspaceLayout.setWindowZoom(workspace, windowId, update), queueThumbnail: true);
  }

  void setWindowIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    if (workspace == null || intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return;
    }

    if (workspace.windows.where((window) => window.asset.id == windowId).isEmpty) {
      return;
    }

    replaceWorkspace(WorkspaceLayout.setWindowIntrinsicSize(workspace, windowId, intrinsicSize), queueThumbnail: true);
  }

  void clearWindowRuntimeState(String windowId) {
    windowInteractionState.previousWindowZOrders.remove(windowId);
  }

  void rememberClosedWindow(
    List<RecentlyClosedWindowEntry> recentlyClosedWindows, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    recentlyClosedWindows.insert(
      0,
      RecentlyClosedWindowEntry(
        workspaceId: workspace.id,
        workspaceName: workspace.name,
        window: window,
        closedAt: DateTime.now(),
      ),
    );

    if (recentlyClosedWindows.length > maxRecentlyClosedWindows) {
      recentlyClosedWindows.removeRange(maxRecentlyClosedWindows, recentlyClosedWindows.length);
    }
  }
}

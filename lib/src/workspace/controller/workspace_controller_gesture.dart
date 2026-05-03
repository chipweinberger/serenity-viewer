part of 'workspace_controller.dart';

class _WorkspaceGestureController {
  _WorkspaceGestureController({required this.windowInteractionState, required this.commitInteractionState});

  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;

  void setActiveWindow(String? windowId) {
    if (windowInteractionState.activeGestureWindowId == windowId) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.activeGestureWindowId = windowId;
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
}

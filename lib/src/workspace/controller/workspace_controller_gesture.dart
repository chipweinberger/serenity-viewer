import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';

class WorkspaceGestureControllerState {
  WorkspaceGestureControllerState({required this.windowInteractionState, required this.commitInteractionState});

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

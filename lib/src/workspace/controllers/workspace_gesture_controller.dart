import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

class WorkspaceGestureController {
  WorkspaceGestureController({required this.windowInteractionState, required this.commitInteractionState});

  final WindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;

  void setActive(String? windowId) {
    if (windowInteractionState.activeGestureWindowId == windowId) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.activeGestureWindowId = windowId;
    });
  }

  void setPinnedHover(String? windowId) {
    if (windowInteractionState.pinnedHoverWindowId == windowId) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.pinnedHoverWindowId = windowId;
    });
  }

  void clearPinnedHover() {
    setPinnedHover(null);
  }
}

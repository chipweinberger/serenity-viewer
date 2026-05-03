import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';

class WorkspaceExposeControllerState {
  WorkspaceExposeControllerState({required this.windowInteractionState, required this.commitInteractionState});

  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;

  void toggleWindowSelected(String windowId) {
    commitInteractionState(() {
      if (windowInteractionState.selectedExposeWindowIds.contains(windowId)) {
        windowInteractionState.selectedExposeWindowIds.remove(windowId);
      } else {
        windowInteractionState.selectedExposeWindowIds.add(windowId);
      }
    });
  }

  void clearWindowSelection() {
    if (windowInteractionState.selectedExposeWindowIds.isEmpty) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.selectedExposeWindowIds.clear();
    });
  }

  int selectedWindowCount(Workspace workspace) {
    return workspace.windows
        .where((window) => windowInteractionState.selectedExposeWindowIds.contains(window.asset.id))
        .length;
  }

  bool isWindowSelected(String windowId) {
    return windowInteractionState.selectedExposeWindowIds.contains(windowId);
  }

  int selectionCount() {
    return windowInteractionState.selectedExposeWindowIds.length;
  }

  bool hasWindowSelection() {
    return windowInteractionState.selectedExposeWindowIds.isNotEmpty;
  }

  Set<String> selectedWindowIds() {
    return {...windowInteractionState.selectedExposeWindowIds};
  }

  void removeWindowSelection(String windowId) {
    windowInteractionState.selectedExposeWindowIds.remove(windowId);
  }
}

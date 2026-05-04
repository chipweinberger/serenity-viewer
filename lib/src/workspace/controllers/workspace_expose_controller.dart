import 'package:serenity_viewer/src/workspace/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

class WorkspaceExposeController {
  WorkspaceExposeController({required this.windowInteractionState, required this.commitInteractionState});

  final WindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;

  void toggle(String windowId) {
    commitInteractionState(() {
      if (windowInteractionState.selectedExposeWindowIds.contains(windowId)) {
        windowInteractionState.selectedExposeWindowIds.remove(windowId);
      } else {
        windowInteractionState.selectedExposeWindowIds.add(windowId);
      }
    });
  }

  void clear() {
    if (windowInteractionState.selectedExposeWindowIds.isEmpty) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.selectedExposeWindowIds.clear();
    });
  }

  int countIn(Workspace workspace) {
    return workspace.windows
        .where((window) => windowInteractionState.selectedExposeWindowIds.contains(window.asset.id))
        .length;
  }

  bool contains(String windowId) {
    return windowInteractionState.selectedExposeWindowIds.contains(windowId);
  }

  int count() {
    return windowInteractionState.selectedExposeWindowIds.length;
  }

  bool hasSelection() {
    return windowInteractionState.selectedExposeWindowIds.isNotEmpty;
  }

  Set<String> ids() {
    return {...windowInteractionState.selectedExposeWindowIds};
  }

  void remove(String windowId) {
    windowInteractionState.selectedExposeWindowIds.remove(windowId);
  }
}

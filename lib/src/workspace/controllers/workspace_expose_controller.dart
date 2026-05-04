import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

class WorkspaceExposeController {
  WorkspaceExposeController({required this.windowInteractionState});

  final WindowInteractionState windowInteractionState;

  void toggle(String windowId) {
    windowInteractionState.toggleSelectedExposeWindow(windowId);
  }

  void clear() {
    windowInteractionState.clearSelectedExposeWindows();
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
    windowInteractionState.removeSelectedExposeWindow(windowId);
  }
}

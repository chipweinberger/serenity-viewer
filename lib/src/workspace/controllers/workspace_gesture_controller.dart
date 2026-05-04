import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

class WorkspaceGestureController {
  WorkspaceGestureController({required this.windowInteractionState});

  final WindowInteractionState windowInteractionState;

  void setActive(String? windowId) {
    windowInteractionState.setActiveGestureWindow(windowId);
  }

  void setPinnedHover(String? windowId) {
    windowInteractionState.setPinnedHoverWindow(windowId);
  }

  void clearPinnedHover() {
    setPinnedHover(null);
  }
}

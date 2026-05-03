part of 'workspace_controller.dart';

class WorkspaceInteractionApi {
  WorkspaceInteractionApi._(this._controller);

  final WorkspaceController _controller;

  void setOptionGestureWindowId(String? windowId) {
    _controller._interactionController.setOptionGestureWindowId(windowId);
  }

  void setPinnedHoverWindow(String? windowId) {
    _controller._interactionController.setPinnedHoverWindow(windowId);
  }

  void clearPinnedHoverWindow() {
    _controller._interactionController.clearPinnedHoverWindow();
  }

  void flashWindow(String windowId, {required bool mounted}) {
    _controller._interactionController.flashWindow(windowId, mounted: mounted);
  }

  void toggleExposeWindowSelected(String windowId) {
    _controller._interactionController.toggleExposeWindowSelected(windowId);
  }

  void clearExposeSelection() {
    _controller._interactionController.clearExposeSelection();
  }

  int selectedExposeWindowCount(Workspace workspace) {
    return _controller._interactionController.selectedExposeWindowCount(workspace);
  }

  void removeWindowSelection(String windowId) {
    _controller._interactionController.removeWindowSelection(windowId);
  }

  void clearWindowRuntimeState(String windowId) {
    _controller._interactionController.clearWindowRuntimeState(windowId);
  }
}

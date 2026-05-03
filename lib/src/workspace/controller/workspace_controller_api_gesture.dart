part of 'workspace_controller.dart';

class WorkspaceGestureApi {
  WorkspaceGestureApi._(this._controller);

  final WorkspaceController _controller;

  void setActiveWindow(String? windowId) {
    _controller._gestureController.setActiveWindow(windowId);
  }

  void setPinnedHoverWindow(String? windowId) {
    _controller._gestureController.setPinnedHoverWindow(windowId);
  }

  void clearPinnedHoverWindow() {
    _controller._gestureController.clearPinnedHoverWindow();
  }
}

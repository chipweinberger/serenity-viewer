import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';

class WorkspaceGestureApi {
  WorkspaceGestureApi(this._controller);

  final WorkspaceController _controller;

  void setActiveWindow(String? windowId) {
    _controller.gestureController.setActiveWindow(windowId);
  }

  void setPinnedHoverWindow(String? windowId) {
    _controller.gestureController.setPinnedHoverWindow(windowId);
  }

  void clearPinnedHoverWindow() {
    _controller.gestureController.clearPinnedHoverWindow();
  }
}

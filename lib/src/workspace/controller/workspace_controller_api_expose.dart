part of 'workspace_controller.dart';

class WorkspaceExposeApi {
  WorkspaceExposeApi._(this._controller);

  final WorkspaceController _controller;

  void toggleWindowSelected(String windowId) {
    _controller._exposeController.toggleWindowSelected(windowId);
  }

  void clearWindowSelection() {
    _controller._exposeController.clearWindowSelection();
  }

  int selectedWindowCount(Workspace workspace) {
    return _controller._exposeController.selectedWindowCount(workspace);
  }

  void removeWindowSelection(String windowId) {
    _controller._exposeController.removeWindowSelection(windowId);
  }
}

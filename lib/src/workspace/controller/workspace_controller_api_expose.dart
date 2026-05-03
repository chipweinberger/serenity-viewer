import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';

class WorkspaceExposeApi {
  WorkspaceExposeApi(this._controller);

  final WorkspaceController _controller;

  void toggleWindowSelected(String windowId) {
    _controller.exposeController.toggleWindowSelected(windowId);
  }

  void clearWindowSelection() {
    _controller.exposeController.clearWindowSelection();
  }

  int selectedWindowCount(Workspace workspace) {
    return _controller.exposeController.selectedWindowCount(workspace);
  }

  bool isWindowSelected(String windowId) {
    return _controller.exposeController.isWindowSelected(windowId);
  }

  int selectionCount() {
    return _controller.exposeController.selectionCount();
  }

  bool hasWindowSelection() {
    return _controller.exposeController.hasWindowSelection();
  }

  Set<String> selectedWindowIds() {
    return _controller.exposeController.selectedWindowIds();
  }

  void removeWindowSelection(String windowId) {
    _controller.exposeController.removeWindowSelection(windowId);
  }
}

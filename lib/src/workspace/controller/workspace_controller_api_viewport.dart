part of 'workspace_controller.dart';

class WorkspaceViewportApi {
  WorkspaceViewportApi._(this._controller);

  final WorkspaceController _controller;

  void handlePanZoomStart(
    PointerPanZoomStartEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    _controller._viewportController.handleWorkspacePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void handlePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    _controller._viewportController.handleWorkspacePanZoomUpdate(event, workspace, viewportSize);
  }

  Future<void> handlePanZoomEnd() async {
    await _controller._viewportController.handleWorkspacePanZoomEnd();
  }

  void fitToContent(Workspace? workspace) {
    _controller.fitWorkspaceViewportToContent(workspace);
  }
}

part of 'workspace_controller.dart';

class WorkspaceWindowApi {
  WorkspaceWindowApi._(this._controller);

  final WorkspaceController _controller;

  Window? focusedOrNull(Workspace? workspace) {
    return _controller._windowController.focusedWindowOrNull(workspace);
  }

  void focus(Workspace workspace, String windowId) {
    _controller._windowController.focusWindow(workspace, windowId);
  }

  void restorePreviousZOrder(Workspace workspace, String windowId) {
    _controller._windowController.restorePreviousWindowZOrder(workspace, windowId);
  }

  void move(Workspace workspace, String windowId, Offset delta) {
    _controller._windowController.moveWindow(workspace, windowId, delta);
  }

  void resize(Workspace workspace, String windowId, AssetWindowResizeHandle handle, Offset delta) {
    _controller._windowController.resizeWindow(workspace, windowId, handle, delta);
  }

  void transformFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
    _controller._windowController.transformWindowFromTrackpad(workspace, windowId, scaleDelta);
  }

  void fitToContent(Workspace? workspace, String windowId) {
    _controller._windowController.fitWindowToContent(workspace, windowId);
  }

  void handleOptionGestureHover(
    PointerHoverEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    _controller._windowController.handleOptionGestureHover(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void setZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    _controller._windowController.setWindowZoom(workspace, windowId, update);
  }

  void setIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    _controller._windowController.setWindowIntrinsicSize(workspace, windowId, intrinsicSize);
  }

  void clearRuntimeState(String windowId) {
    _controller._windowController.clearWindowRuntimeState(windowId);
  }

  void rememberClosedWindow(
    List<RecentlyClosedWindowEntry> recentlyClosedWindows, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    _controller._windowController.rememberClosedWindow(
      recentlyClosedWindows,
      maxRecentlyClosedWindows: maxRecentlyClosedWindows,
      workspace: workspace,
      window: window,
    );
  }

  bool canCollate(Workspace? workspace) {
    return _controller.canCollateWorkspaceWindows(workspace);
  }

  int collatableCount(Workspace workspace) {
    return _controller.collatableWindowCount(workspace);
  }

  void collate(Workspace workspace) {
    _controller.collateWorkspaceWindows(workspace);
  }
}

part of 'workspace_controller.dart';

extension WorkspaceControllerLegacyApi on WorkspaceController {
  Window? focusedWindowOrNull(Workspace? workspace) {
    return windows.focusedOrNull(workspace);
  }

  void setOptionGestureWindowId(String? windowId) {
    interaction.setOptionGestureWindowId(windowId);
  }

  void setPinnedHoverWindow(String? windowId) {
    interaction.setPinnedHoverWindow(windowId);
  }

  void clearPinnedHoverWindow() {
    interaction.clearPinnedHoverWindow();
  }

  void flashWindow(String windowId, {required bool mounted}) {
    interaction.flashWindow(windowId, mounted: mounted);
  }

  void toggleExposeWindowSelected(String windowId) {
    interaction.toggleExposeWindowSelected(windowId);
  }

  void clearExposeSelection() {
    interaction.clearExposeSelection();
  }

  void focusWindow(Workspace workspace, String windowId) {
    windows.focus(workspace, windowId);
  }

  void restorePreviousWindowZOrder(Workspace workspace, String windowId) {
    windows.restorePreviousZOrder(workspace, windowId);
  }

  void moveWindow(Workspace workspace, String windowId, Offset delta) {
    windows.move(workspace, windowId, delta);
  }

  void resizeWindow(Workspace workspace, String windowId, AssetWindowResizeHandle handle, Offset delta) {
    windows.resize(workspace, windowId, handle, delta);
  }

  void transformWindowFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
    windows.transformFromTrackpad(workspace, windowId, scaleDelta);
  }

  void fitWindowToContent(Workspace? workspace, String windowId) {
    windows.fitToContent(workspace, windowId);
  }

  void handleOptionGestureHover(
    PointerHoverEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    windows.handleOptionGestureHover(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void handleWorkspacePanZoomStart(
    PointerPanZoomStartEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    viewport.handlePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    viewport.handlePanZoomUpdate(event, workspace, viewportSize);
  }

  Future<void> handleWorkspacePanZoomEnd() async {
    await viewport.handlePanZoomEnd();
  }

  void setWindowZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    windows.setZoom(workspace, windowId, update);
  }

  void setVideoPosition(Workspace? workspace, String windowId, int positionMs) {
    playback.setPosition(workspace, windowId, positionMs);
  }

  void cycleVideoPlaybackSpeed(Workspace? workspace, String windowId) {
    playback.cycleSpeed(workspace, windowId);
  }

  void setWindowIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    windows.setIntrinsicSize(workspace, windowId, intrinsicSize);
  }

  bool isVideoWindowPaused(String windowId) {
    return playback.isPaused(windowId);
  }

  void toggleVideoPlayback(Workspace? workspace, String windowId) {
    playback.toggle(workspace, windowId);
  }

  void pauseAllVideos(Environment? environment) {
    playback.stopAll(environment);
  }

  void removeWindowSelection(String windowId) {
    interaction.removeWindowSelection(windowId);
  }

  void clearWindowRuntimeState(String windowId) {
    interaction.clearWindowRuntimeState(windowId);
    windows.clearRuntimeState(windowId);
  }

  void rememberClosedWindow(
    List<RecentlyClosedWindowEntry> recentlyClosedWindows, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    windows.rememberClosedWindow(
      recentlyClosedWindows,
      maxRecentlyClosedWindows: maxRecentlyClosedWindows,
      workspace: workspace,
      window: window,
    );
  }

  void toggleWorkspaceOpen(Environment environment, String workspaceId, void Function(Environment) updateEnvironment) {
    this.environment.toggleWorkspaceOpen(environment, workspaceId, updateEnvironment);
  }

  void reorderOpenWorkspace(
    Environment? environment,
    List<Workspace> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required void Function(Environment) updateEnvironment,
  }) {
    this.environment.reorderOpenWorkspace(
      environment,
      workspaces,
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      updateEnvironment: updateEnvironment,
    );
  }

  bool canMoveSelectedWindowsToWorkspace({
    required Environment? environment,
    required Workspace? sourceWorkspace,
    required String destinationWorkspaceId,
  }) {
    return this.environment.canMoveSelectedWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
    );
  }

  int selectedExposeWindowCount(Workspace workspace) {
    return interaction.selectedExposeWindowCount(workspace);
  }

  void moveSelectedExposeWindowsToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
  }) {
    this.environment.moveSelectedExposeWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
      updateEnvironment: updateEnvironment,
      queueThumbnailRefresh: queueThumbnailRefresh,
    );
  }
}

// ignore_for_file: invalid_use_of_protected_member

part of 'app_shell.dart';

extension _AppShellWindowActions on _AppShellState {
  bool get _isCommandPressedForContentGesture {
    return isCommandPressed();
  }

  bool get _isOptionPressedForWindowGesture {
    return isOptionPressed();
  }

  void _setOptionGestureWindowId(String? windowId) {
    _workspaceController.setOptionGestureWindowId(windowId);
  }

  void _handleOptionGestureHover(PointerHoverEvent event, WorkspaceState workspace) {
    _workspaceController.handleOptionGestureHover(
      event,
      workspace,
      isCommandPressedForContentGesture: _isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: _isOptionPressedForWindowGesture,
    );
  }

  void _focusWindow(String windowId) {
    _workspaceController.focusWindow(_activeWorkspace, windowId);
  }

  void _restorePreviousWindowZOrder(String windowId) {
    _workspaceController.restorePreviousWindowZOrder(_activeWorkspace, windowId);
  }

  void _moveWindow(String windowId, Offset delta) {
    _workspaceController.moveWindow(_activeWorkspace, windowId, delta);
  }

  void _collateWorkspaceWindows() {
    final workspace = _activeWorkspaceOrNull;
    if (!_workspaceController.canCollateWorkspaceWindows(workspace)) {
      return;
    }

    _workspaceController.collateWorkspaceWindows(workspace!);
  }

  Future<void> _confirmCollateWorkspaceWindows() async {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null || _uiState.workspaceLayoutMode != WorkspaceLayoutMode.freeform) {
      return;
    }

    final collatableWindowCount = _workspaceController.collatableWindowCount(workspace);
    if (collatableWindowCount == 0) {
      _showMessage('There are no image or video windows to collate.');
      return;
    }

    final shouldCollate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Collate Windows?'),
          content: Text(
            'Center and resize $collatableWindowCount image/video window'
            '${collatableWindowCount == 1 ? '' : 's'} into a fixed ${WorkspaceController.collateTargetBox.width.toInt()} × '
            '${WorkspaceController.collateTargetBox.height.toInt()} box?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Collate')),
          ],
        );
      },
    );

    if (shouldCollate == true && mounted) {
      _collateWorkspaceWindows();
    }
  }

  void _resizeWindow(String windowId, WindowResizeHandle handle, Offset delta) {
    _workspaceController.resizeWindow(_activeWorkspace, windowId, handle, delta);
  }

  void _transformWindowFromTrackpad(String windowId, double scaleDelta, Offset localFocalPoint) {
    _workspaceController.transformWindowFromTrackpad(_activeWorkspace, windowId, scaleDelta);
  }

  void _fitWindowToContent(String windowId) {
    _workspaceController.fitWindowToContent(_activeWorkspaceOrNull, windowId);
  }

  void _fitWorkspaceViewportToContent() {
    _workspaceController.fitWorkspaceViewportToContent(_activeWorkspaceOrNull);
  }

  void _handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, WorkspaceState workspace) {
    _workspaceController.handleWorkspacePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: _isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: _isOptionPressedForWindowGesture,
    );
  }

  void _handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, WorkspaceState workspace, Size viewportSize) {
    _workspaceController.handleWorkspacePanZoomUpdate(event, workspace, viewportSize);
  }

  void _handleWorkspacePanZoomEnd() {
    unawaited(_workspaceController.handleWorkspacePanZoomEnd());
  }

  void _setWindowZoom(String windowId, WindowZoomUpdate update) {
    _workspaceController.setWindowZoom(_activeWorkspace, windowId, update);
  }

  void _setVideoPosition(String windowId, int positionMs) {
    _workspaceController.setVideoPosition(_activeWorkspaceOrNull, windowId, positionMs);
  }

  void _cycleVideoPlaybackSpeed(String windowId) {
    _workspaceController.cycleVideoPlaybackSpeed(_activeWorkspaceOrNull, windowId);
  }

  void _setWindowIntrinsicSize(String windowId, Size intrinsicSize) {
    _workspaceController.setWindowIntrinsicSize(_activeWorkspaceOrNull, windowId, intrinsicSize);
  }

  bool _isVideoWindowPaused(String windowId) {
    return _workspaceController.isVideoWindowPaused(windowId);
  }

  void _toggleVideoPlayback(String windowId) {
    _workspaceController.toggleVideoPlayback(_activeWorkspaceOrNull, windowId);
  }

  void _pauseAllVideos() {
    _workspaceController.pauseAllVideos(_persistenceState.session);
  }
}

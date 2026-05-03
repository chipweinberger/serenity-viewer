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
    _workspaceController.interaction.setOptionGestureWindowId(windowId);
  }

  void _handleOptionGestureHover(PointerHoverEvent event, Workspace workspace) {
    _workspaceController.windows.handleOptionGestureHover(
      event,
      workspace,
      isCommandPressedForContentGesture: _isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: _isOptionPressedForWindowGesture,
    );
  }

  void _focusWindow(String windowId) {
    _workspaceController.windows.focus(_activeWorkspace, windowId);
  }

  void _restorePreviousWindowZOrder(String windowId) {
    _workspaceController.windows.restorePreviousZOrder(_activeWorkspace, windowId);
  }

  void _moveWindow(String windowId, Offset delta) {
    _workspaceController.windows.move(_activeWorkspace, windowId, delta);
  }

  void _collateWorkspaceWindows() {
    final workspace = _activeWorkspaceOrNull;
    if (!_workspaceController.windows.canCollate(workspace)) {
      return;
    }

    _workspaceController.windows.collate(workspace!);
  }

  Future<void> _confirmCollateWorkspaceWindows() async {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null || _uiState.workspaceLayoutMode != WorkspaceLayoutMode.freeform) {
      return;
    }

    final collatableWindowCount = _workspaceController.windows.collatableCount(workspace);
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
            '${collatableWindowCount == 1 ? '' : 's'} into a fixed ${workspaceCollateTargetBox.width.toInt()} × '
            '${workspaceCollateTargetBox.height.toInt()} box?',
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

  void _resizeWindow(String windowId, AssetWindowResizeHandle handle, Offset delta) {
    _workspaceController.windows.resize(_activeWorkspace, windowId, handle, delta);
  }

  void _transformWindowFromTrackpad(String windowId, double scaleDelta, Offset localFocalPoint) {
    _workspaceController.windows.transformFromTrackpad(_activeWorkspace, windowId, scaleDelta);
  }

  void _fitWindowToContent(String windowId) {
    _workspaceController.windows.fitToContent(_activeWorkspaceOrNull, windowId);
  }

  void _fitWorkspaceViewportToContent() {
    _workspaceController.viewport.fitToContent(_activeWorkspaceOrNull);
  }

  void _handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, Workspace workspace) {
    _workspaceController.viewport.handlePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: _isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: _isOptionPressedForWindowGesture,
    );
  }

  void _handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    _workspaceController.viewport.handlePanZoomUpdate(event, workspace, viewportSize);
  }

  void _handleWorkspacePanZoomEnd() {
    unawaited(_workspaceController.viewport.handlePanZoomEnd());
  }

  void _setWindowZoom(String windowId, AssetWindowZoomUpdate update) {
    _workspaceController.windows.setZoom(_activeWorkspace, windowId, update);
  }

  void _setVideoPosition(String windowId, int positionMs) {
    _workspaceController.playback.setPosition(_activeWorkspaceOrNull, windowId, positionMs);
  }

  void _cycleVideoPlaybackSpeed(String windowId) {
    _workspaceController.playback.cycleSpeed(_activeWorkspaceOrNull, windowId);
  }

  void _setWindowIntrinsicSize(String windowId, Size intrinsicSize) {
    _workspaceController.windows.setIntrinsicSize(_activeWorkspaceOrNull, windowId, intrinsicSize);
  }

  bool _isVideoWindowPaused(String windowId) {
    return _workspaceController.playback.isPaused(windowId);
  }

  void _toggleVideoPlayback(String windowId) {
    _workspaceController.playback.toggle(_activeWorkspaceOrNull, windowId);
  }

  void _pauseAllVideos() {
    _workspaceController.playback.stopAll(_persistenceState.environment);
  }
}

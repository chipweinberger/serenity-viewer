// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellWindowActions on _SerenityShellState {
  static const Size _collateTargetBox = Size(700, 700);

  bool get _isCommandPressedForContentGesture {
    return isCommandPressed();
  }

  bool get _isOptionPressedForWindowGesture {
    return isOptionPressed();
  }

  void _setOptionGestureWindowId(String? windowId) {
    if (_windowInteractionState.optionGestureWindowId == windowId) {
      return;
    }
    setState(() {
      _windowInteractionState.optionGestureWindowId = windowId;
    });
  }

  void _handleOptionGestureHover(PointerHoverEvent event, WorkspaceState workspace) {
    final targetWindowId = _windowInteractionState.optionGestureWindowId;
    if (_uiState.screen != SerenityScreen.workspace || _uiState.workspaceLayoutMode == WorkspaceLayoutMode.expose) {
      return;
    }
    if (_isCommandPressedForContentGesture || !_isOptionPressedForWindowGesture || targetWindowId == null) {
      return;
    }
    if (event.delta == Offset.zero) {
      return;
    }

    _moveWindow(targetWindowId, event.delta / workspace.viewportZoom);
  }

  void _focusWindow(String windowId) {
    final workspace = _activeWorkspace;
    final result = SerenityWorkspaceMutations.focusWindow(workspace, windowId);
    if (identical(result.workspace, workspace)) {
      return;
    }

    if (result.previousZOrder != null) {
      _windowInteractionState.previousWindowZOrders[windowId] = result.previousZOrder!;
    }
    _replaceWorkspace(result.workspace);
  }

  void _restorePreviousWindowZOrder(String windowId) {
    final workspace = _activeWorkspace;
    final previousZ = _windowInteractionState.previousWindowZOrders.remove(windowId);
    if (previousZ == null) {
      return;
    }

    _replaceWorkspace(SerenityWorkspaceMutations.restorePreviousWindowZOrder(workspace, windowId, previousZ));
  }

  void _moveWindow(String windowId, Offset delta) {
    final workspace = _activeWorkspace;
    _replaceWorkspace(SerenityWorkspaceMutations.moveWindow(workspace, windowId, delta));
  }

  void _collateWorkspaceWindows() {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null || _uiState.workspaceLayoutMode == WorkspaceLayoutMode.expose) {
      return;
    }

    final collatableWindows = workspace.windows
        .where((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video)
        .toList();
    if (collatableWindows.isEmpty) {
      return;
    }

    _replaceWorkspace(
      SerenityWorkspaceMutations.collateWorkspaceWindows(workspace, targetBox: _collateTargetBox),
      queueThumbnail: true,
    );
  }

  Future<void> _confirmCollateWorkspaceWindows() async {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null || _uiState.workspaceLayoutMode != WorkspaceLayoutMode.freeform) {
      return;
    }

    final collatableWindows = workspace.windows
        .where((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video)
        .toList();
    if (collatableWindows.isEmpty) {
      _showMessage('There are no image or video windows to collate.');
      return;
    }

    final shouldCollate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Collate Windows?'),
          content: Text(
            'Center and resize ${collatableWindows.length} image/video window'
            '${collatableWindows.length == 1 ? '' : 's'} into a fixed ${_collateTargetBox.width.toInt()} × '
            '${_collateTargetBox.height.toInt()} box?',
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
    final workspace = _activeWorkspace;
    _replaceWorkspace(SerenityWorkspaceMutations.resizeWindow(workspace, windowId, handle, delta));
  }

  void _transformWindowFromTrackpad(String windowId, double scaleDelta, Offset localFocalPoint) {
    final workspace = _activeWorkspace;
    _replaceWorkspace(SerenityWorkspaceMutations.transformWindowFromTrackpad(workspace, windowId, scaleDelta));
  }

  void _fitWindowToContent(String windowId) {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null) {
      return;
    }

    final matchingWindow = workspace.windows.where((window) => window.asset.id == windowId);
    if (matchingWindow.isEmpty) {
      return;
    }

    _replaceWorkspace(SerenityWorkspaceMutations.fitWindowToContent(workspace, windowId));
  }

  void _fitWorkspaceViewportToContent() {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null) {
      return;
    }

    if (_workspaceViewportState.viewportSize.width <= 0 ||
        _workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      _setWorkspaceViewport(workspaceId: workspace.id, center: defaultWorkspaceCenter, zoom: 1, queueThumbnail: true);
      return;
    }
    _replaceWorkspace(
      SerenityWorkspaceMutations.fitWorkspaceViewportToContent(workspace, _workspaceViewportState.viewportSize),
      queueThumbnail: true,
    );
  }

  void _handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, WorkspaceState workspace) {
    if (_uiState.screen != SerenityScreen.workspace || _uiState.workspaceLayoutMode == WorkspaceLayoutMode.expose) {
      _workspaceViewportState.isGestureActive = false;
      return;
    }
    if (_windowInteractionState.pinnedHoverWindowId != null) {
      _workspaceViewportState.isGestureActive = false;
      return;
    }
    if (_isCommandPressedForContentGesture || _isOptionPressedForWindowGesture) {
      _workspaceViewportState.isGestureActive = false;
      return;
    }

    _workspaceViewportState.isGestureActive = true;
    _workspaceViewportState.gestureStartCenter = workspace.viewportCenter;
    _workspaceViewportState.gestureStartZoom = workspace.viewportZoom;
    _workspaceViewportState.gestureStartLocalFocalPoint = event.localPosition;
    _workspaceViewportState.gestureAccumulatedPan = Offset.zero;
  }

  void _handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, WorkspaceState workspace, Size viewportSize) {
    if (!_workspaceViewportState.isGestureActive) {
      return;
    }

    _workspaceViewportState.gestureAccumulatedPan += event.panDelta;
    final nextZoom = _clampWorkspaceZoom(
      _workspaceViewportState.gestureStartZoom * math.pow(event.scale, 1.15).toDouble(),
    );
    final viewportCenter = viewportSize.center(Offset.zero);
    final anchorWorldPoint =
        _workspaceViewportState.gestureStartCenter +
        ((_workspaceViewportState.gestureStartLocalFocalPoint - viewportCenter) /
            _workspaceViewportState.gestureStartZoom);
    final nextAnchorLocalPoint =
        _workspaceViewportState.gestureStartLocalFocalPoint + _workspaceViewportState.gestureAccumulatedPan;
    final nextCenter = _clampWorkspaceCenter(
      center: anchorWorldPoint - ((nextAnchorLocalPoint - viewportCenter) / nextZoom),
      zoom: nextZoom,
      viewportSize: viewportSize,
    );
    _setWorkspaceViewport(workspaceId: workspace.id, center: nextCenter, zoom: nextZoom, queueThumbnail: false);
  }

  void _handleWorkspacePanZoomEnd() {
    _workspaceViewportState.isGestureActive = false;
    _workspaceViewportState.gestureAccumulatedPan = Offset.zero;
    unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
  }

  void _setWindowZoom(String windowId, WindowZoomUpdate update) {
    final workspace = _activeWorkspace;
    _replaceWorkspace(SerenityWorkspaceMutations.setWindowZoom(workspace, windowId, update));
  }

  void _setVideoPosition(String windowId, int positionMs) {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null) {
      return;
    }

    final matchingWindow = workspace.windows.where((window) => window.asset.id == windowId);
    if (matchingWindow.isEmpty) {
      return;
    }

    final currentWindow = matchingWindow.first;
    if (currentWindow.videoPositionMs == positionMs) {
      return;
    }

    _replaceWorkspace(
      SerenityWorkspaceMutations.setVideoPosition(workspace, windowId, positionMs),
      queueThumbnail: false,
    );
  }

  void _cycleVideoPlaybackSpeed(String windowId) {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null) {
      return;
    }

    final matchingWindow = workspace.windows.where(
      (window) => window.asset.id == windowId && window.asset.type == AssetType.video,
    );
    if (matchingWindow.isEmpty) {
      return;
    }

    _replaceWorkspace(SerenityWorkspaceMutations.cycleVideoPlaybackSpeed(workspace, windowId), queueThumbnail: false);
  }

  void _setWindowIntrinsicSize(String windowId, Size intrinsicSize) {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null || intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return;
    }

    final matchingWindow = workspace.windows.where((window) => window.asset.id == windowId);
    if (matchingWindow.isEmpty) {
      return;
    }

    _replaceWorkspace(SerenityWorkspaceMutations.setWindowIntrinsicSize(workspace, windowId, intrinsicSize));
  }

  bool _isVideoWindowPaused(String windowId) {
    return _windowInteractionState.pausedVideoWindows[windowId] ?? true;
  }

  void _toggleVideoPlayback(String windowId) {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null) {
      return;
    }

    final matches = workspace.windows.where(
      (window) => window.asset.id == windowId && window.asset.type == AssetType.video,
    );
    if (matches.isEmpty) {
      return;
    }

    setState(() {
      _windowInteractionState.pausedVideoWindows[windowId] =
          !(_windowInteractionState.pausedVideoWindows[windowId] ?? true);
    });
  }

  void _pauseAllVideos() {
    final session = _persistenceState.session;
    if (session == null) {
      return;
    }

    setState(() {
      for (final workspace in session.workspaces) {
        for (final window in workspace.windows) {
          if (window.asset.type == AssetType.video) {
            _windowInteractionState.pausedVideoWindows[window.asset.id] = true;
          }
        }
      }
    });
  }
}

// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellWindowActions on _SerenityShellState {
  static const Size _collateTargetBox = Size(700, 700);

  bool get _isCommandPressedForContentGesture {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    return pressedKeys.contains(LogicalKeyboardKey.metaLeft) || pressedKeys.contains(LogicalKeyboardKey.metaRight);
  }

  bool get _isOptionPressedForWindowGesture {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    return pressedKeys.contains(LogicalKeyboardKey.altLeft) || pressedKeys.contains(LogicalKeyboardKey.altRight);
  }

  void _setOptionGestureWindowId(String? windowId) {
    if (_optionGestureWindowId == windowId) {
      return;
    }
    setState(() {
      _optionGestureWindowId = windowId;
    });
  }

  void _handleOptionGestureHover(PointerHoverEvent event, WorkspaceState workspace) {
    final targetWindowId = _optionGestureWindowId;
    if (_screen != SerenityScreen.workspace || _workspaceLayoutMode == WorkspaceLayoutMode.expose) {
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
      _previousWindowZOrders[windowId] = result.previousZOrder!;
    }
    _replaceWorkspace(result.workspace);
  }

  void _restorePreviousWindowZOrder(String windowId) {
    final workspace = _activeWorkspace;
    final previousZ = _previousWindowZOrders.remove(windowId);
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
    if (workspace == null || _workspaceLayoutMode == WorkspaceLayoutMode.expose) {
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
    if (workspace == null || _workspaceLayoutMode != WorkspaceLayoutMode.freeform) {
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

    if (_workspaceViewportSize.width <= 0 || _workspaceViewportSize.height <= 0 || workspace.windows.isEmpty) {
      _setWorkspaceViewport(workspaceId: workspace.id, center: defaultWorkspaceCenter, zoom: 1, queueThumbnail: true);
      return;
    }
    _replaceWorkspace(
      SerenityWorkspaceMutations.fitWorkspaceViewportToContent(workspace, _workspaceViewportSize),
      queueThumbnail: true,
    );
  }

  void _handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, WorkspaceState workspace) {
    if (_screen != SerenityScreen.workspace || _workspaceLayoutMode == WorkspaceLayoutMode.expose) {
      _isWorkspaceGestureActive = false;
      return;
    }
    if (_pinnedHoverWindowId != null) {
      _isWorkspaceGestureActive = false;
      return;
    }
    if (_isCommandPressedForContentGesture || _isOptionPressedForWindowGesture) {
      _isWorkspaceGestureActive = false;
      return;
    }

    _isWorkspaceGestureActive = true;
    _workspaceGestureStartCenter = workspace.viewportCenter;
    _workspaceGestureStartZoom = workspace.viewportZoom;
    _workspaceGestureStartLocalFocalPoint = event.localPosition;
    _workspaceGestureAccumulatedPan = Offset.zero;
  }

  void _handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, WorkspaceState workspace, Size viewportSize) {
    if (!_isWorkspaceGestureActive) {
      return;
    }

    _workspaceGestureAccumulatedPan += event.panDelta;
    final nextZoom = _clampWorkspaceZoom(_workspaceGestureStartZoom * math.pow(event.scale, 1.15).toDouble());
    final viewportCenter = viewportSize.center(Offset.zero);
    final anchorWorldPoint =
        _workspaceGestureStartCenter +
        ((_workspaceGestureStartLocalFocalPoint - viewportCenter) / _workspaceGestureStartZoom);
    final nextAnchorLocalPoint = _workspaceGestureStartLocalFocalPoint + _workspaceGestureAccumulatedPan;
    final nextCenter = _clampWorkspaceCenter(
      center: anchorWorldPoint - ((nextAnchorLocalPoint - viewportCenter) / nextZoom),
      zoom: nextZoom,
      viewportSize: viewportSize,
    );
    _setWorkspaceViewport(workspaceId: workspace.id, center: nextCenter, zoom: nextZoom, queueThumbnail: false);
  }

  void _handleWorkspacePanZoomEnd() {
    _isWorkspaceGestureActive = false;
    _workspaceGestureAccumulatedPan = Offset.zero;
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
    return _pausedVideoWindows[windowId] ?? true;
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
      _pausedVideoWindows[windowId] = !(_pausedVideoWindows[windowId] ?? true);
    });
  }

  void _pauseAllVideos() {
    final session = _session;
    if (session == null) {
      return;
    }

    setState(() {
      for (final workspace in session.workspaces) {
        for (final window in workspace.windows) {
          if (window.asset.type == AssetType.video) {
            _pausedVideoWindows[window.asset.id] = true;
          }
        }
      }
    });
  }
}

// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellWindowActions on _SerenityShellState {
  static const List<double> _videoPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0];

  void _focusWindow(String windowId) {
    final workspace = _activeWorkspace;
    final matchingWindow = workspace.windows.where((window) => window.asset.id == windowId);
    if (matchingWindow.isEmpty) {
      return;
    }

    final currentWindow = matchingWindow.first;
    final maxZ = workspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    if (currentWindow.zIndex == maxZ) {
      return;
    }

    _previousWindowZOrders[windowId] = currentWindow.zIndex;

    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows
            .map((window) => window.asset.id == windowId ? window.copyWith(zIndex: maxZ + 1) : window)
            .toList(),
      ),
    );
    if (_screen == SerenityScreen.workspace) {
      _workspaceLayoutMode = WorkspaceLayoutMode.freeform;
    }
  }

  void _restorePreviousWindowZOrder(String windowId) {
    final workspace = _activeWorkspace;
    final previousZ = _previousWindowZOrders.remove(windowId);
    if (previousZ == null) {
      return;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final currentIndex = sortedWindows.indexWhere((window) => window.asset.id == windowId);
    if (currentIndex == -1) {
      return;
    }

    final targetWindow = sortedWindows.removeAt(currentIndex);
    var insertIndex = sortedWindows.indexWhere((window) => window.zIndex > previousZ);
    if (insertIndex == -1) {
      insertIndex = sortedWindows.length;
    }
    sortedWindows.insert(insertIndex, targetWindow);

    final reindexedWindows = sortedWindows
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(zIndex: entry.key + 1))
        .toList();
    final reindexedById = {for (final window in reindexedWindows) window.asset.id: window};

    _replaceWorkspace(
      workspace.copyWith(windows: workspace.windows.map((window) => reindexedById[window.asset.id] ?? window).toList()),
    );
  }

  void _moveWindow(String windowId, Offset delta) {
    final workspace = _activeWorkspace;
    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows
            .map(
              (window) => window.asset.id == windowId
                  ? window.copyWith(position: _clampWindowPosition(window.position + delta, window.size))
                  : window,
            )
            .toList(),
      ),
    );
  }

  void _resizeWindow(String windowId, WindowResizeHandle handle, Offset delta) {
    final workspace = _activeWorkspace;
    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) {
          if (window.asset.id != windowId) {
            return window;
          }

          const minWidth = 96.0;
          const minHeight = 72.0;

          var left = window.position.dx;
          var top = window.position.dy;
          var right = window.position.dx + window.size.width;
          var bottom = window.position.dy + window.size.height;

          switch (handle) {
            case WindowResizeHandle.left:
              left += delta.dx;
              break;
            case WindowResizeHandle.right:
              right += delta.dx;
              break;
            case WindowResizeHandle.top:
              top += delta.dy;
              break;
            case WindowResizeHandle.bottom:
              bottom += delta.dy;
              break;
            case WindowResizeHandle.topLeft:
              left += delta.dx;
              top += delta.dy;
              break;
            case WindowResizeHandle.topRight:
              right += delta.dx;
              top += delta.dy;
              break;
            case WindowResizeHandle.bottomLeft:
              left += delta.dx;
              bottom += delta.dy;
              break;
            case WindowResizeHandle.bottomRight:
              right += delta.dx;
              bottom += delta.dy;
              break;
          }

          var width = right - left;
          if (width < minWidth) {
            if ({WindowResizeHandle.left, WindowResizeHandle.topLeft, WindowResizeHandle.bottomLeft}.contains(handle)) {
              left = right - minWidth;
            } else {
              right = left + minWidth;
            }
            width = minWidth;
          }

          var height = bottom - top;
          if (height < minHeight) {
            if ({WindowResizeHandle.top, WindowResizeHandle.topLeft, WindowResizeHandle.topRight}.contains(handle)) {
              top = bottom - minHeight;
            } else {
              bottom = top + minHeight;
            }
            height = minHeight;
          }

          width = width.clamp(minWidth, _workspaceExtent * 2);
          height = height.clamp(minHeight, _workspaceExtent * 2);
          left = left.clamp(_workspaceMinCoordinate, _workspaceMaxCoordinate - width);
          top = top.clamp(_workspaceMinCoordinate, _workspaceMaxCoordinate - height);

          return window.copyWith(position: Offset(left, top), size: Size(width, height));
        }).toList(),
      ),
    );
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

    final currentWindow = matchingWindow.first;
    final intrinsicWidth = currentWindow.asset.intrinsicWidth;
    final intrinsicHeight = currentWindow.asset.intrinsicHeight;
    if (intrinsicWidth == null || intrinsicHeight == null || intrinsicWidth <= 0 || intrinsicHeight <= 0) {
      return;
    }

    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) {
          if (window.asset.id != windowId) {
            return window;
          }
          final nextSize = _windowSizeByFittingAspect(
            currentSize: window.size,
            contentWidth: intrinsicWidth,
            contentHeight: intrinsicHeight,
          );
          return window.copyWith(position: _clampWindowPosition(window.position, nextSize), size: nextSize);
        }).toList(),
      ),
    );
  }

  void _fitWorkspaceViewportToContent() {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null) {
      return;
    }

    if (_workspaceViewportSize.width <= 0 || _workspaceViewportSize.height <= 0 || workspace.windows.isEmpty) {
      _setWorkspaceViewport(workspaceId: workspace.id, center: _defaultWorkspaceCenter, zoom: 1, queueThumbnail: true);
      return;
    }

    var minX = workspace.windows.first.position.dx;
    var minY = workspace.windows.first.position.dy;
    var maxX = workspace.windows.first.position.dx + workspace.windows.first.size.width;
    var maxY = workspace.windows.first.position.dy + workspace.windows.first.size.height;
    for (final window in workspace.windows.skip(1)) {
      minX = math.min(minX, window.position.dx);
      minY = math.min(minY, window.position.dy);
      maxX = math.max(maxX, window.position.dx + window.size.width);
      maxY = math.max(maxY, window.position.dy + window.size.height);
    }

    const padding = 120.0;
    final contentWidth = math.max(1.0, (maxX - minX) + padding);
    final contentHeight = math.max(1.0, (maxY - minY) + padding);
    final zoom = _clampWorkspaceZoom(
      math.min(_workspaceViewportSize.width / contentWidth, _workspaceViewportSize.height / contentHeight),
    );
    _setWorkspaceViewport(
      workspaceId: workspace.id,
      center: Offset((minX + maxX) / 2, (minY + maxY) / 2),
      zoom: zoom,
      queueThumbnail: true,
    );
  }

  void _handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, WorkspaceState workspace, Size viewportSize) {
    if (_screen != SerenityScreen.workspace || _workspaceLayoutMode == WorkspaceLayoutMode.expose) {
      _isWorkspaceGestureActive = false;
      return;
    }
    if (_isPointOverWorkspaceWindow(event.localPosition, workspace, viewportSize)) {
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
    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows
            .map(
              (window) => window.asset.id == windowId
                  ? window.copyWith(
                      zoom: update.zoom,
                      zoomBaseWidth: update.zoomBaseSize?.width,
                      zoomBaseHeight: update.zoomBaseSize?.height,
                      contentOffsetDx: update.contentOffset?.dx,
                      contentOffsetDy: update.contentOffset?.dy,
                      clearZoomBase: update.clearZoomBase,
                      clearContentOffset: update.clearContentOffset,
                    )
                  : window,
            )
            .toList(),
      ),
    );
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
      workspace.copyWith(
        windows: workspace.windows
            .map((window) => window.asset.id == windowId ? window.copyWith(videoPositionMs: positionMs) : window)
            .toList(),
      ),
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

    final currentWindow = matchingWindow.first;
    final currentIndex = _videoPlaybackSpeeds.indexWhere(
      (speed) => (speed - currentWindow.videoPlaybackSpeed).abs() < 0.001,
    );
    final nextSpeed = _videoPlaybackSpeeds[(currentIndex + 1) % _videoPlaybackSpeeds.length];

    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows
            .map((window) => window.asset.id == windowId ? window.copyWith(videoPlaybackSpeed: nextSpeed) : window)
            .toList(),
      ),
      queueThumbnail: false,
    );
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

    final currentWindow = matchingWindow.first;
    final currentWidth = currentWindow.asset.intrinsicWidth;
    final currentHeight = currentWindow.asset.intrinsicHeight;
    final shouldAdoptContentSize =
        currentWidth == null &&
        currentHeight == null &&
        ((currentWindow.asset.type == AssetType.video && currentWindow.size == const Size(520, 340)) ||
            (currentWindow.asset.type == AssetType.image && currentWindow.size == const Size(420, 300)));
    if (currentWidth != null &&
        currentHeight != null &&
        (currentWidth - intrinsicSize.width).abs() < 0.001 &&
        (currentHeight - intrinsicSize.height).abs() < 0.001) {
      return;
    }

    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) {
          if (window.asset.id != windowId) {
            return window;
          }
          final nextSize = shouldAdoptContentSize
              ? _windowSizeByFittingAspect(
                  currentSize: currentWindow.size,
                  contentWidth: intrinsicSize.width,
                  contentHeight: intrinsicSize.height,
                )
              : null;
          return window.copyWith(
            position: nextSize == null ? null : _clampWindowPosition(window.position, nextSize),
            size: nextSize,
            zoom: shouldAdoptContentSize ? 1 : null,
            clearZoomBase: shouldAdoptContentSize,
            clearContentOffset: shouldAdoptContentSize,
            asset: window.asset.copyWith(intrinsicWidth: intrinsicSize.width, intrinsicHeight: intrinsicSize.height),
          );
        }).toList(),
      ),
    );
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

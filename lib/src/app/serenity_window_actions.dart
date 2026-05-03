// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellWindowActions on _SerenityShellState {
  static const List<double> _videoPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0];
  static const double _minWindowWidth = 96.0;
  static const double _minWindowHeight = 72.0;
  static const double _maxContentZoom = 30.0;
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

  AssetWindowState _scaleWindowAroundCenter(
    AssetWindowState window,
    double scaleDelta, {
    required bool mirrorContentZoom,
  }) {
    final clampedScaleDelta = scaleDelta.clamp(0.5, 2.0);
    final focalWorldPoint = Offset(
      window.position.dx + (window.size.width / 2),
      window.position.dy + (window.size.height / 2),
    );
    final nextWidth = (window.size.width * clampedScaleDelta).clamp(_minWindowWidth, _workspaceExtent * 2).toDouble();
    final nextHeight = (window.size.height * clampedScaleDelta)
        .clamp(_minWindowHeight, _workspaceExtent * 2)
        .toDouble();
    final nextSize = Size(nextWidth, nextHeight);
    final nextPosition = _clampWindowPosition(
      Offset(focalWorldPoint.dx - (nextWidth / 2), focalWorldPoint.dy - (nextHeight / 2)),
      nextSize,
    );
    final shouldScaleContentZoom = mirrorContentZoom || window.zoom > 1.0 || window.zoomBaseSize != null;
    final nextZoom = shouldScaleContentZoom
        ? (window.zoom * clampedScaleDelta).clamp(1.0, _maxContentZoom).toDouble()
        : window.zoom;
    final snappedZoom = (nextZoom - 1).abs() < 0.02 ? 1.0 : nextZoom;
    final nextContentOffset = snappedZoom > 1.0 ? window.contentOffset * clampedScaleDelta : Offset.zero;
    final nextZoomBaseSize = snappedZoom > 1.0
        ? Size(
            (window.zoomBaseSize?.width ?? window.size.width) * clampedScaleDelta,
            (window.zoomBaseSize?.height ?? window.size.height) * clampedScaleDelta,
          )
        : null;

    return window.copyWith(
      position: nextPosition,
      size: nextSize,
      zoom: snappedZoom,
      zoomBaseWidth: nextZoomBaseSize?.width,
      zoomBaseHeight: nextZoomBaseSize?.height,
      contentOffsetDx: nextContentOffset.dx,
      contentOffsetDy: nextContentOffset.dy,
      clearZoomBase: snappedZoom <= 1.0,
      clearContentOffset: snappedZoom <= 1.0,
    );
  }

  ({Rect visibleRect, Size zoomedContentSize}) _visibleContentRectForWindow(AssetWindowState window) {
    final fitSize = _fitSizeForViewportToAspect(window.size, window.asset.aspectRatio);
    final baseSize = window.zoom > 1.0 && window.zoomBaseSize != null ? window.zoomBaseSize! : fitSize;
    final zoomedContentSize = Size(baseSize.width * window.zoom, baseSize.height * window.zoom);
    final left = ((window.size.width - zoomedContentSize.width) / 2) + window.contentOffset.dx;
    final top = ((window.size.height - zoomedContentSize.height) / 2) + window.contentOffset.dy;
    final visibleLeft = math.max(0.0, left);
    final visibleTop = math.max(0.0, top);
    final visibleRight = math.min(window.size.width, left + zoomedContentSize.width);
    final visibleBottom = math.min(window.size.height, top + zoomedContentSize.height);

    return (
      visibleRect: Rect.fromLTRB(visibleLeft, visibleTop, visibleRight, visibleBottom),
      zoomedContentSize: zoomedContentSize,
    );
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

    final targetCenter = workspace.viewportCenter;

    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) {
          if (window.asset.type != AssetType.image && window.asset.type != AssetType.video) {
            return window;
          }

          final targetSize = _fitSizeForViewportToAspect(_collateTargetBox, window.asset.aspectRatio);
          if (targetSize.width <= 0 || targetSize.height <= 0) {
            return window;
          }

          final centeredPosition = _clampWindowPosition(
            Offset(targetCenter.dx - (targetSize.width / 2), targetCenter.dy - (targetSize.height / 2)),
            targetSize,
          );
          return window.copyWith(
            position: centeredPosition,
            size: targetSize,
            zoom: 1,
            clearZoomBase: true,
            clearContentOffset: true,
          );
        }).toList(),
      ),
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
    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) {
          if (window.asset.id != windowId) {
            return window;
          }

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
          if (width < _minWindowWidth) {
            if ({WindowResizeHandle.left, WindowResizeHandle.topLeft, WindowResizeHandle.bottomLeft}.contains(handle)) {
              left = right - _minWindowWidth;
            } else {
              right = left + _minWindowWidth;
            }
            width = _minWindowWidth;
          }

          var height = bottom - top;
          if (height < _minWindowHeight) {
            if ({WindowResizeHandle.top, WindowResizeHandle.topLeft, WindowResizeHandle.topRight}.contains(handle)) {
              top = bottom - _minWindowHeight;
            } else {
              bottom = top + _minWindowHeight;
            }
            height = _minWindowHeight;
          }

          width = width.clamp(_minWindowWidth, _workspaceExtent * 2);
          height = height.clamp(_minWindowHeight, _workspaceExtent * 2);
          left = left.clamp(_workspaceMinCoordinate, _workspaceMaxCoordinate - width);
          top = top.clamp(_workspaceMinCoordinate, _workspaceMaxCoordinate - height);

          return window.copyWith(position: Offset(left, top), size: Size(width, height));
        }).toList(),
      ),
    );
  }

  void _transformWindowFromTrackpad(String windowId, double scaleDelta, Offset localFocalPoint) {
    final workspace = _activeWorkspace;
    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) {
          if (window.asset.id != windowId) {
            return window;
          }
          return _scaleWindowAroundCenter(window, scaleDelta, mirrorContentZoom: false);
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
    final visibleContent = _visibleContentRectForWindow(currentWindow);
    final visibleRect = visibleContent.visibleRect;
    final visibleWidth = math.max(1.0, visibleRect.width);
    final visibleHeight = math.max(1.0, visibleRect.height);
    final nextSize = Size(
      visibleWidth.clamp(_minWindowWidth, _workspaceExtent * 2),
      visibleHeight.clamp(_minWindowHeight, _workspaceExtent * 2),
    );
    final nextPosition = _clampWindowPosition(currentWindow.position + visibleRect.topLeft, nextSize);
    final nextLeft =
        ((currentWindow.size.width - visibleContent.zoomedContentSize.width) / 2) +
        currentWindow.contentOffset.dx -
        visibleRect.left;
    final nextTop =
        ((currentWindow.size.height - visibleContent.zoomedContentSize.height) / 2) +
        currentWindow.contentOffset.dy -
        visibleRect.top;
    final nextContentOffset = Offset(
      nextLeft - ((nextSize.width - visibleContent.zoomedContentSize.width) / 2),
      nextTop - ((nextSize.height - visibleContent.zoomedContentSize.height) / 2),
    );

    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) {
          if (window.asset.id != windowId) {
            return window;
          }
          return window.copyWith(
            position: nextPosition,
            size: nextSize,
            contentOffsetDx: currentWindow.zoom > 1.0 ? nextContentOffset.dx : 0,
            contentOffsetDy: currentWindow.zoom > 1.0 ? nextContentOffset.dy : 0,
            clearContentOffset: currentWindow.zoom <= 1.0,
          );
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

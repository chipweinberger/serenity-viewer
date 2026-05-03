part of 'workspace_mutations.dart';

WorkspaceState _moveWindow(WorkspaceState workspace, String windowId, Offset delta) {
  return _updateWindowById(
    workspace,
    windowId,
    (window) => window.copyWith(position: _clampWindowPosition(window.position + delta, window.size)),
  );
}

WorkspaceState _collateWorkspaceWindows(WorkspaceState workspace, {required Size targetBox}) {
  final targetCenter = workspace.viewportCenter;
  return _mapWindows(workspace, (window) {
    if (window.asset.type != AssetType.image && window.asset.type != AssetType.video) {
      return window;
    }

    final targetSize = fitSizeForViewportToAspect(targetBox, window.asset.aspectRatio);
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
  });
}

WorkspaceState _resizeWindow(WorkspaceState workspace, String windowId, AssetWindowResizeHandle handle, Offset delta) {
  return _updateWindowById(workspace, windowId, (window) => _resizeWindowState(window, handle, delta));
}

WorkspaceState _transformWindowFromTrackpad(WorkspaceState workspace, String windowId, double scaleDelta) {
  return _updateWindowById(
    workspace,
    windowId,
    (window) => _scaleWindowAroundCenter(window, scaleDelta, mirrorContentZoom: false),
  );
}

WorkspaceState _fitWindowToContent(WorkspaceState workspace, String windowId) {
  final currentWindow = _windowById(workspace, windowId);
  if (currentWindow == null) {
    return workspace;
  }

  return _updateWindowById(workspace, windowId, (_) => _fitWindowToVisibleContent(currentWindow));
}

WorkspaceState _setWindowZoom(WorkspaceState workspace, String windowId, AssetWindowZoomUpdate update) {
  return _updateWindowById(
    workspace,
    windowId,
    (window) => window.copyWith(
      zoom: update.zoom,
      zoomBaseWidth: update.zoomBaseSize?.width,
      zoomBaseHeight: update.zoomBaseSize?.height,
      contentOffsetDx: update.contentOffset?.dx,
      contentOffsetDy: update.contentOffset?.dy,
      clearZoomBase: update.clearZoomBase,
      clearContentOffset: update.clearContentOffset,
    ),
  );
}

WorkspaceState _setVideoPosition(WorkspaceState workspace, String windowId, int positionMs) {
  return _updateWindowById(workspace, windowId, (window) => window.copyWith(videoPositionMs: positionMs));
}

WorkspaceState _cycleVideoPlaybackSpeed(WorkspaceState workspace, String windowId) {
  final currentWindow = _videoWindowById(workspace, windowId);
  if (currentWindow == null) {
    return workspace;
  }

  final currentIndex = WorkspaceMutations.videoPlaybackSpeeds.indexWhere(
    (speed) => (speed - currentWindow.videoPlaybackSpeed).abs() < 0.001,
  );
  final nextSpeed =
      WorkspaceMutations.videoPlaybackSpeeds[(currentIndex + 1) % WorkspaceMutations.videoPlaybackSpeeds.length];

  return _updateWindowById(workspace, windowId, (window) => window.copyWith(videoPlaybackSpeed: nextSpeed));
}

WorkspaceState _setWindowIntrinsicSize(WorkspaceState workspace, String windowId, Size intrinsicSize) {
  if (intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
    return workspace;
  }

  final currentWindow = _windowById(workspace, windowId);
  if (currentWindow == null) {
    return workspace;
  }

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
    return workspace;
  }

  return _updateWindowById(workspace, windowId, (window) {
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
  });
}

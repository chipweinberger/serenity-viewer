part of 'serenity_workspace_mutations.dart';

Offset _clampWindowPosition(Offset position, Size size) {
  return Offset(
    position.dx.clamp(workspaceMinCoordinate, math.max(workspaceMinCoordinate, workspaceMaxCoordinate - size.width)),
    position.dy.clamp(workspaceMinCoordinate, math.max(workspaceMinCoordinate, workspaceMaxCoordinate - size.height)),
  );
}

Size _windowSizeByFittingAspect({
  required Size currentSize,
  required double contentWidth,
  required double contentHeight,
}) {
  if (contentWidth <= 0 || contentHeight <= 0) {
    return currentSize;
  }

  final aspectRatio = contentWidth / contentHeight;
  final currentAspectRatio = currentSize.width / currentSize.height;

  if (currentAspectRatio > aspectRatio) {
    final nextWidth = math.max(SerenityWorkspaceMutations.minWindowWidth, currentSize.height * aspectRatio);
    return Size(math.min(currentSize.width, nextWidth), currentSize.height);
  }

  if (currentAspectRatio < aspectRatio) {
    final nextHeight = math.max(SerenityWorkspaceMutations.minWindowHeight, currentSize.width / aspectRatio);
    return Size(currentSize.width, math.min(currentSize.height, nextHeight));
  }

  return currentSize;
}

({double left, double top, double right, double bottom}) _windowEdges(AssetWindowState window) {
  return (
    left: window.position.dx,
    top: window.position.dy,
    right: window.position.dx + window.size.width,
    bottom: window.position.dy + window.size.height,
  );
}

({double left, double top, double right, double bottom}) _applyResizeDelta(
  ({double left, double top, double right, double bottom}) edges,
  WindowResizeHandle handle,
  Offset delta,
) {
  var left = edges.left;
  var top = edges.top;
  var right = edges.right;
  var bottom = edges.bottom;

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

  return (left: left, top: top, right: right, bottom: bottom);
}

bool _resizesFromLeft(WindowResizeHandle handle) {
  return {WindowResizeHandle.left, WindowResizeHandle.topLeft, WindowResizeHandle.bottomLeft}.contains(handle);
}

bool _resizesFromTop(WindowResizeHandle handle) {
  return {WindowResizeHandle.top, WindowResizeHandle.topLeft, WindowResizeHandle.topRight}.contains(handle);
}

({Offset position, Size size}) _clampResizedBounds(
  ({double left, double top, double right, double bottom}) edges,
  WindowResizeHandle handle,
) {
  var left = edges.left;
  var top = edges.top;
  var right = edges.right;
  var bottom = edges.bottom;

  var width = right - left;
  if (width < SerenityWorkspaceMutations.minWindowWidth) {
    if (_resizesFromLeft(handle)) {
      left = right - SerenityWorkspaceMutations.minWindowWidth;
    } else {
      right = left + SerenityWorkspaceMutations.minWindowWidth;
    }
    width = SerenityWorkspaceMutations.minWindowWidth;
  }

  var height = bottom - top;
  if (height < SerenityWorkspaceMutations.minWindowHeight) {
    if (_resizesFromTop(handle)) {
      top = bottom - SerenityWorkspaceMutations.minWindowHeight;
    } else {
      bottom = top + SerenityWorkspaceMutations.minWindowHeight;
    }
    height = SerenityWorkspaceMutations.minWindowHeight;
  }

  width = width.clamp(SerenityWorkspaceMutations.minWindowWidth, workspaceExtent * 2);
  height = height.clamp(SerenityWorkspaceMutations.minWindowHeight, workspaceExtent * 2);
  left = left.clamp(workspaceMinCoordinate, workspaceMaxCoordinate - width);
  top = top.clamp(workspaceMinCoordinate, workspaceMaxCoordinate - height);

  return (position: Offset(left, top), size: Size(width, height));
}

WorkspaceState _moveWindow(WorkspaceState workspace, String windowId, Offset delta) {
  return _updateWindowById(
    workspace,
    windowId,
    (window) => window.copyWith(position: _clampWindowPosition(window.position + delta, window.size)),
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
  final nextWidth = (window.size.width * clampedScaleDelta)
      .clamp(SerenityWorkspaceMutations.minWindowWidth, workspaceExtent * 2)
      .toDouble();
  final nextHeight = (window.size.height * clampedScaleDelta)
      .clamp(SerenityWorkspaceMutations.minWindowHeight, workspaceExtent * 2)
      .toDouble();
  final nextSize = Size(nextWidth, nextHeight);
  final nextPosition = _clampWindowPosition(
    Offset(focalWorldPoint.dx - (nextWidth / 2), focalWorldPoint.dy - (nextHeight / 2)),
    nextSize,
  );
  final shouldScaleContentZoom = mirrorContentZoom || window.zoom > 1.0 || window.zoomBaseSize != null;
  final nextZoom = shouldScaleContentZoom
      ? (window.zoom * clampedScaleDelta).clamp(1.0, SerenityWorkspaceMutations.maxContentZoom).toDouble()
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
  final fitSize = fitSizeForViewportToAspect(window.size, window.asset.aspectRatio);
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

({Offset position, Size size}) _resizedBoundsForWindow(
  AssetWindowState window,
  WindowResizeHandle handle,
  Offset delta,
) {
  final resizedEdges = _applyResizeDelta(_windowEdges(window), handle, delta);
  return _clampResizedBounds(resizedEdges, handle);
}

AssetWindowState _resizeWindowState(AssetWindowState window, WindowResizeHandle handle, Offset delta) {
  final nextBounds = _resizedBoundsForWindow(window, handle, delta);
  return window.copyWith(position: nextBounds.position, size: nextBounds.size);
}

AssetWindowState _fitWindowToVisibleContent(AssetWindowState currentWindow) {
  final visibleContent = _visibleContentRectForWindow(currentWindow);
  final visibleRect = visibleContent.visibleRect;
  final nextSize = Size(
    math.max(1.0, visibleRect.width).clamp(SerenityWorkspaceMutations.minWindowWidth, workspaceExtent * 2),
    math.max(1.0, visibleRect.height).clamp(SerenityWorkspaceMutations.minWindowHeight, workspaceExtent * 2),
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

  return currentWindow.copyWith(
    position: nextPosition,
    size: nextSize,
    contentOffsetDx: currentWindow.zoom > 1.0 ? nextContentOffset.dx : 0,
    contentOffsetDy: currentWindow.zoom > 1.0 ? nextContentOffset.dy : 0,
    clearContentOffset: currentWindow.zoom <= 1.0,
  );
}

WorkspaceState _resizeWindow(WorkspaceState workspace, String windowId, WindowResizeHandle handle, Offset delta) {
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

WorkspaceState _setWindowZoom(WorkspaceState workspace, String windowId, WindowZoomUpdate update) {
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

  final currentIndex = SerenityWorkspaceMutations.videoPlaybackSpeeds.indexWhere(
    (speed) => (speed - currentWindow.videoPlaybackSpeed).abs() < 0.001,
  );
  final nextSpeed = SerenityWorkspaceMutations
      .videoPlaybackSpeeds[(currentIndex + 1) % SerenityWorkspaceMutations.videoPlaybackSpeeds.length];

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

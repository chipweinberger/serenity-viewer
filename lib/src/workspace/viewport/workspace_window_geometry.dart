part of 'package:serenity_viewer/src/workspace/workspace_mutations.dart';

typedef _WindowEdges = ({double left, double top, double right, double bottom});
typedef _WindowBounds = ({Offset position, Size size});
typedef _VisibleWindowContent = ({Rect visibleRect, Size zoomedContentSize});

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
    final nextWidth = math.max(WorkspaceMutations.minWindowWidth, currentSize.height * aspectRatio);
    return Size(math.min(currentSize.width, nextWidth), currentSize.height);
  }

  if (currentAspectRatio < aspectRatio) {
    final nextHeight = math.max(WorkspaceMutations.minWindowHeight, currentSize.width / aspectRatio);
    return Size(currentSize.width, math.min(currentSize.height, nextHeight));
  }

  return currentSize;
}

_WindowEdges _windowEdges(WorkspaceWindowState window) {
  return (
    left: window.position.dx,
    top: window.position.dy,
    right: window.position.dx + window.size.width,
    bottom: window.position.dy + window.size.height,
  );
}

_WindowEdges _applyResizeDelta(_WindowEdges edges, AssetWindowResizeHandle handle, Offset delta) {
  var left = edges.left;
  var top = edges.top;
  var right = edges.right;
  var bottom = edges.bottom;

  switch (handle) {
    case AssetWindowResizeHandle.left:
      left += delta.dx;
      break;
    case AssetWindowResizeHandle.right:
      right += delta.dx;
      break;
    case AssetWindowResizeHandle.top:
      top += delta.dy;
      break;
    case AssetWindowResizeHandle.bottom:
      bottom += delta.dy;
      break;
    case AssetWindowResizeHandle.topLeft:
      left += delta.dx;
      top += delta.dy;
      break;
    case AssetWindowResizeHandle.topRight:
      right += delta.dx;
      top += delta.dy;
      break;
    case AssetWindowResizeHandle.bottomLeft:
      left += delta.dx;
      bottom += delta.dy;
      break;
    case AssetWindowResizeHandle.bottomRight:
      right += delta.dx;
      bottom += delta.dy;
      break;
  }

  return (left: left, top: top, right: right, bottom: bottom);
}

bool _resizesFromLeft(AssetWindowResizeHandle handle) {
  return {
    AssetWindowResizeHandle.left,
    AssetWindowResizeHandle.topLeft,
    AssetWindowResizeHandle.bottomLeft,
  }.contains(handle);
}

bool _resizesFromTop(AssetWindowResizeHandle handle) {
  return {
    AssetWindowResizeHandle.top,
    AssetWindowResizeHandle.topLeft,
    AssetWindowResizeHandle.topRight,
  }.contains(handle);
}

_WindowBounds _clampResizedBounds(_WindowEdges edges, AssetWindowResizeHandle handle) {
  var left = edges.left;
  var top = edges.top;
  var right = edges.right;
  var bottom = edges.bottom;

  var width = right - left;
  if (width < WorkspaceMutations.minWindowWidth) {
    if (_resizesFromLeft(handle)) {
      left = right - WorkspaceMutations.minWindowWidth;
    } else {
      right = left + WorkspaceMutations.minWindowWidth;
    }
    width = WorkspaceMutations.minWindowWidth;
  }

  var height = bottom - top;
  if (height < WorkspaceMutations.minWindowHeight) {
    if (_resizesFromTop(handle)) {
      top = bottom - WorkspaceMutations.minWindowHeight;
    } else {
      bottom = top + WorkspaceMutations.minWindowHeight;
    }
    height = WorkspaceMutations.minWindowHeight;
  }

  width = width.clamp(WorkspaceMutations.minWindowWidth, workspaceExtent * 2);
  height = height.clamp(WorkspaceMutations.minWindowHeight, workspaceExtent * 2);
  left = left.clamp(workspaceMinCoordinate, workspaceMaxCoordinate - width);
  top = top.clamp(workspaceMinCoordinate, workspaceMaxCoordinate - height);

  return (position: Offset(left, top), size: Size(width, height));
}

_WindowBounds _resizedBoundsForWindow(WorkspaceWindowState window, AssetWindowResizeHandle handle, Offset delta) {
  final resizedEdges = _applyResizeDelta(_windowEdges(window), handle, delta);
  return _clampResizedBounds(resizedEdges, handle);
}

WorkspaceWindowState _resizeWindowState(WorkspaceWindowState window, AssetWindowResizeHandle handle, Offset delta) {
  final nextBounds = _resizedBoundsForWindow(window, handle, delta);
  return window.copyWith(position: nextBounds.position, size: nextBounds.size);
}

WorkspaceWindowState _scaleWindowAroundCenter(
  WorkspaceWindowState window,
  double scaleDelta, {
  required bool mirrorContentZoom,
}) {
  final clampedScaleDelta = scaleDelta.clamp(0.5, 2.0);
  final focalWorldPoint = Offset(
    window.position.dx + (window.size.width / 2),
    window.position.dy + (window.size.height / 2),
  );
  final nextWidth = (window.size.width * clampedScaleDelta)
      .clamp(WorkspaceMutations.minWindowWidth, workspaceExtent * 2)
      .toDouble();
  final nextHeight = (window.size.height * clampedScaleDelta)
      .clamp(WorkspaceMutations.minWindowHeight, workspaceExtent * 2)
      .toDouble();
  final nextSize = Size(nextWidth, nextHeight);
  final nextPosition = _clampWindowPosition(
    Offset(focalWorldPoint.dx - (nextWidth / 2), focalWorldPoint.dy - (nextHeight / 2)),
    nextSize,
  );
  final shouldScaleContentZoom = mirrorContentZoom || window.zoom > 1.0 || window.zoomBaseSize != null;
  final nextZoom = shouldScaleContentZoom
      ? (window.zoom * clampedScaleDelta).clamp(1.0, WorkspaceMutations.maxContentZoom).toDouble()
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

_VisibleWindowContent _visibleContentRectForWindow(WorkspaceWindowState window) {
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

WorkspaceWindowState _fitWindowToVisibleContent(WorkspaceWindowState currentWindow) {
  final visibleContent = _visibleContentRectForWindow(currentWindow);
  final visibleRect = visibleContent.visibleRect;
  final nextSize = Size(
    math.max(1.0, visibleRect.width).clamp(WorkspaceMutations.minWindowWidth, workspaceExtent * 2),
    math.max(1.0, visibleRect.height).clamp(WorkspaceMutations.minWindowHeight, workspaceExtent * 2),
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

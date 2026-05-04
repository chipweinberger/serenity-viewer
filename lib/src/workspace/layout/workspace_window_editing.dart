part of 'workspace_layout.dart';

Workspace _moveWindow(Workspace workspace, String windowId, Offset delta) {
  return WorkspaceWindowModelHelpers.updateWindowById(
    workspace,
    windowId,
    (window) => window.copyWith(position: _clampWindowPosition(window.position + delta, window.size)),
  );
}

Workspace _resizeWindow(Workspace workspace, String windowId, WindowResizeHandle handle, Offset delta) {
  return WorkspaceWindowModelHelpers.updateWindowById(
    workspace,
    windowId,
    (window) => _resizeWindowState(window, handle, delta),
  );
}

Workspace _transformWindowFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
  return WorkspaceWindowModelHelpers.updateWindowById(
    workspace,
    windowId,
    (window) => _scaleWindowAroundCenter(window, scaleDelta, mirrorContentZoom: false),
  );
}

Workspace _fitWindowToContent(Workspace workspace, String windowId) {
  final currentWindow = WorkspaceWindowModelHelpers.windowById(workspace, windowId);
  if (currentWindow == null) {
    return workspace;
  }

  return WorkspaceWindowModelHelpers.updateWindowById(
    workspace,
    windowId,
    (_) => _fitWindowToVisibleContent(currentWindow),
  );
}

Workspace _setWindowZoom(Workspace workspace, String windowId, WindowZoomUpdate update) {
  return WorkspaceWindowModelHelpers.updateWindowById(
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

Workspace _setWindowIntrinsicSize(Workspace workspace, String windowId, Size intrinsicSize) {
  if (intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
    return workspace;
  }

  final currentWindow = WorkspaceWindowModelHelpers.windowById(workspace, windowId);
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

  return WorkspaceWindowModelHelpers.updateWindowById(workspace, windowId, (window) {
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

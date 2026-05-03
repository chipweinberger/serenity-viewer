part of 'workspace_mutations.dart';

double _clampWorkspaceZoom(double zoom) {
  return zoom.clamp(workspaceMinZoom, workspaceMaxZoom);
}

Offset _clampWorkspaceCenter({required Offset center, required double zoom, required Size viewportSize}) {
  final safeZoom = _clampWorkspaceZoom(zoom);
  final halfVisibleWidth = viewportSize.width <= 0 ? 0.0 : viewportSize.width / (2 * safeZoom);
  final halfVisibleHeight = viewportSize.height <= 0 ? 0.0 : viewportSize.height / (2 * safeZoom);

  final minCenterX = halfVisibleWidth >= workspaceExtent ? 0.0 : workspaceMinCoordinate + halfVisibleWidth;
  final maxCenterX = halfVisibleWidth >= workspaceExtent ? 0.0 : workspaceMaxCoordinate - halfVisibleWidth;
  final minCenterY = halfVisibleHeight >= workspaceExtent ? 0.0 : workspaceMinCoordinate + halfVisibleHeight;
  final maxCenterY = halfVisibleHeight >= workspaceExtent ? 0.0 : workspaceMaxCoordinate - halfVisibleHeight;

  return Offset(center.dx.clamp(minCenterX, maxCenterX), center.dy.clamp(minCenterY, maxCenterY));
}

WorkspaceState _setWorkspaceViewport(
  WorkspaceState workspace, {
  required Size viewportSize,
  Offset? center,
  double? zoom,
}) {
  final nextZoom = _clampWorkspaceZoom(zoom ?? workspace.viewportZoom);
  final nextCenter = _clampWorkspaceCenter(
    center: center ?? workspace.viewportCenter,
    zoom: nextZoom,
    viewportSize: viewportSize,
  );

  return workspace.copyWith(viewportCenterDx: nextCenter.dx, viewportCenterDy: nextCenter.dy, viewportZoom: nextZoom);
}

Rect _workspaceContentBounds(List<AssetWindowState> windows) {
  var minX = windows.first.position.dx;
  var minY = windows.first.position.dy;
  var maxX = windows.first.position.dx + windows.first.size.width;
  var maxY = windows.first.position.dy + windows.first.size.height;

  for (final window in windows.skip(1)) {
    minX = math.min(minX, window.position.dx);
    minY = math.min(minY, window.position.dy);
    maxX = math.max(maxX, window.position.dx + window.size.width);
    maxY = math.max(maxY, window.position.dy + window.size.height);
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

WorkspaceState _fitWorkspaceViewportToContent(WorkspaceState workspace, Size viewportSize) {
  if (viewportSize.width <= 0 || viewportSize.height <= 0 || workspace.windows.isEmpty) {
    return _setWorkspaceViewport(workspace, viewportSize: viewportSize, center: defaultWorkspaceCenter, zoom: 1);
  }

  final contentBounds = _workspaceContentBounds(workspace.windows);
  const padding = 120.0;
  final contentWidth = math.max(1.0, contentBounds.width + padding);
  final contentHeight = math.max(1.0, contentBounds.height + padding);
  final zoom = _clampWorkspaceZoom(math.min(viewportSize.width / contentWidth, viewportSize.height / contentHeight));
  return _setWorkspaceViewport(workspace, viewportSize: viewportSize, center: contentBounds.center, zoom: zoom);
}

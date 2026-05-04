part of 'workspace_layout.dart';

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

Workspace _setWorkspaceViewport(Workspace workspace, {required Size viewportSize, Offset? center, double? zoom}) {
  final nextZoom = _clampWorkspaceZoom(zoom ?? workspace.viewportZoom);
  final nextCenter = _clampWorkspaceCenter(
    center: center ?? workspace.viewportCenter,
    zoom: nextZoom,
    viewportSize: viewportSize,
  );

  return workspace.copyWith(viewportCenterDx: nextCenter.dx, viewportCenterDy: nextCenter.dy, viewportZoom: nextZoom);
}

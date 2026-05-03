part of 'workspace_layout.dart';

Rect _workspaceContentBounds(List<WorkspaceWindowState> windows) {
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

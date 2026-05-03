import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/workspace/windows/asset_window_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';

Offset workspaceScreenOffsetForWindow(
  WorkspaceState workspace,
  AssetWindowState window,
  Size viewportSize, {
  Offset viewportOffset = Offset.zero,
  double viewportScale = 1.0,
}) {
  final viewportCenter = viewportSize.center(Offset.zero);
  return Offset(
    viewportOffset.dx +
        ((viewportCenter.dx + ((window.position.dx - workspace.viewportCenter.dx) * workspace.viewportZoom)) *
            viewportScale),
    viewportOffset.dy +
        ((viewportCenter.dy + ((window.position.dy - workspace.viewportCenter.dy) * workspace.viewportZoom)) *
            viewportScale),
  );
}

Rect workspaceScreenRectForWindow(
  WorkspaceState workspace,
  AssetWindowState window,
  Size viewportSize, {
  Offset viewportOffset = Offset.zero,
  double viewportScale = 1.0,
}) {
  final offset = workspaceScreenOffsetForWindow(
    workspace,
    window,
    viewportSize,
    viewportOffset: viewportOffset,
    viewportScale: viewportScale,
  );
  return Rect.fromLTWH(
    offset.dx,
    offset.dy,
    (window.size.width * workspace.viewportZoom * viewportScale).clamp(1.0, double.infinity),
    (window.size.height * workspace.viewportZoom * viewportScale).clamp(1.0, double.infinity),
  );
}

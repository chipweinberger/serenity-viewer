import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/workspace/window/frame/window_resize_helpers.dart';
import 'package:serenity_viewer/src/workspace/window/content/asset_zoom_utils.dart';
import 'package:serenity_viewer/src/workspace/window/interaction/window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/workspace_model_helpers.dart';

part 'workspace_collate_logic.dart';
part 'workspace_viewport_bounds.dart';
part 'workspace_zoom_to_fit_logic.dart';
part '../viewport/workspace_window_geometry.dart';
part 'workspace_window_editing.dart';

/// Pure layout helpers for viewport math and window geometry.
///
/// File map:
/// - `workspace_collate_logic.dart`: the user-facing collate feature
/// - `workspace_viewport_bounds.dart`: viewport clamping and updates
/// - `workspace_zoom_to_fit_logic.dart`: the user-facing zoom-to-fit feature
/// - `workspace_window_editing.dart`: moving, resizing, zooming, and fit-to-content geometry updates
class WorkspaceLayout {
  static const double minWindowWidth = 96.0;
  static const double minWindowHeight = 72.0;
  static const double maxContentZoom = 30.0;

  static double clampWorkspaceZoom(double zoom) {
    return _clampWorkspaceZoom(zoom);
  }

  static Offset clampWorkspaceCenter({required Offset center, required double zoom, required Size viewportSize}) {
    return _clampWorkspaceCenter(center: center, zoom: zoom, viewportSize: viewportSize);
  }

  static Workspace setWorkspaceViewport(
    Workspace workspace, {
    required Size viewportSize,
    Offset? center,
    double? zoom,
  }) {
    return _setWorkspaceViewport(workspace, viewportSize: viewportSize, center: center, zoom: zoom);
  }

  static Workspace fitWorkspaceViewportToContent(Workspace workspace, Size viewportSize) {
    return _fitWorkspaceViewportToContent(workspace, viewportSize);
  }

  static Offset clampWindowPosition(Offset position, Size size) {
    return _clampWindowPosition(position, size);
  }

  static Size windowSizeByFittingAspect({
    required Size currentSize,
    required double contentWidth,
    required double contentHeight,
  }) {
    return _windowSizeByFittingAspect(
      currentSize: currentSize,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    );
  }

  static Workspace moveWindow(Workspace workspace, String windowId, Offset delta) {
    return _moveWindow(workspace, windowId, delta);
  }

  static Window scaleWindowAroundCenter(Window window, double scaleDelta, {required bool mirrorContentZoom}) {
    return _scaleWindowAroundCenter(window, scaleDelta, mirrorContentZoom: mirrorContentZoom);
  }

  static ({Rect visibleRect, Size zoomedContentSize}) visibleContentRectForWindow(Window window) {
    return _visibleContentRectForWindow(window);
  }

  static Workspace collateWorkspaceWindows(Workspace workspace, {required Size targetBox}) {
    return _collateWorkspaceWindows(workspace, targetBox: targetBox);
  }

  static Workspace resizeWindow(Workspace workspace, String windowId, WindowResizeHandle handle, Offset delta) {
    return _resizeWindow(workspace, windowId, handle, delta);
  }

  static Workspace transformWindowFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
    return _transformWindowFromTrackpad(workspace, windowId, scaleDelta);
  }

  static Workspace fitWindowToContent(Workspace workspace, String windowId) {
    return _fitWindowToContent(workspace, windowId);
  }

  static Workspace setWindowZoom(Workspace workspace, String windowId, WindowZoomUpdate update) {
    return _setWindowZoom(workspace, windowId, update);
  }

  static Workspace setWindowIntrinsicSize(Workspace workspace, String windowId, Size intrinsicSize) {
    return _setWindowIntrinsicSize(workspace, windowId, intrinsicSize);
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';

class WorkspaceWindowApi {
  WorkspaceWindowApi(this._controller);

  final WorkspaceController _controller;

  Window? focusedOrNull(Workspace? workspace) {
    return _controller.windowController.focusedWindowOrNull(workspace);
  }

  void focus(Workspace workspace, String windowId) {
    _controller.windowController.focusWindow(workspace, windowId);
  }

  void restorePreviousZOrder(Workspace workspace, String windowId) {
    _controller.windowController.restorePreviousWindowZOrder(workspace, windowId);
  }

  void move(Workspace workspace, String windowId, Offset delta) {
    _controller.windowController.moveWindow(workspace, windowId, delta);
  }

  void resize(Workspace workspace, String windowId, AssetWindowResizeHandle handle, Offset delta) {
    _controller.windowController.resizeWindow(workspace, windowId, handle, delta);
  }

  void transformFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
    _controller.windowController.transformWindowFromTrackpad(workspace, windowId, scaleDelta);
  }

  void fitToContent(Workspace? workspace, String windowId) {
    _controller.windowController.fitWindowToContent(workspace, windowId);
  }

  void handleOptionGestureHover(
    PointerHoverEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    _controller.windowController.handleOptionGestureHover(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void setZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    _controller.windowController.setWindowZoom(workspace, windowId, update);
  }

  void setIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    _controller.windowController.setWindowIntrinsicSize(workspace, windowId, intrinsicSize);
  }

  void flash(String windowId, {required bool mounted}) {
    _controller.windowController.flashWindow(windowId, mounted: mounted);
  }

  void clearRuntimeState(String windowId) {
    _controller.windowController.clearWindowRuntimeState(windowId);
  }

  void rememberClosedWindow(
    List<RecentlyClosedWindowEntry> recentlyClosedWindows, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    _controller.windowController.rememberClosedWindow(
      recentlyClosedWindows,
      maxRecentlyClosedWindows: maxRecentlyClosedWindows,
      workspace: workspace,
      window: window,
    );
  }

  bool canCollate(Workspace? workspace) {
    return _controller.windowController.canCollateWorkspaceWindows(workspace);
  }

  int collatableCount(Workspace workspace) {
    return _controller.windowController.collatableWindowCount(workspace);
  }

  void collate(Workspace workspace) {
    _controller.windowController.collateWorkspaceWindows(workspace);
  }
}

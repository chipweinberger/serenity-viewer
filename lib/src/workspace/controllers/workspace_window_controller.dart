// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/app/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/window/frame/window_resize_helpers.dart';
import 'package:serenity_viewer/src/window/interaction/window_zoom_update.dart';

class WorkspaceWindowController {
  const WorkspaceWindowController({
    required this.appUiState,
    required this.environment,
    required this.activeWorkspace,
    required this.activeWorkspaceOrNull,
    required this.workspaceController,
  });

  final AppUiState appUiState;
  final Environment? Function() environment;
  final Workspace Function() activeWorkspace;
  final Workspace? Function() activeWorkspaceOrNull;
  final WorkspaceController workspaceController;

  void setActiveGestureWindow(String? windowId) {
    workspaceController.gesture.setActive(windowId);
  }

  void setPinnedHoverWindow(String? windowId) {
    workspaceController.gesture.setPinnedHover(windowId);
  }

  void clearPinnedHoverWindow() {
    setPinnedHoverWindow(null);
  }

  void handleOptionGestureHover(PointerHoverEvent event, Workspace workspace) {
    workspaceController.windows.editing.handleOptionHover(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressed(),
      isOptionPressedForWindowGesture: isOptionPressed(),
    );
  }

  void focusWindow(String windowId) {
    final result = workspaceController.windows.arrangement.focus(activeWorkspace(), windowId);
    if (result?.previousZOrder != null) {
      workspaceController.windowInteractionState.previousWindowZOrders[windowId] = result!.previousZOrder!;
    }
  }

  Window? focusedWindowOrNull() {
    return workspaceController.windows.arrangement.focusedOrNull(activeWorkspaceOrNull());
  }

  void restorePreviousWindowZOrder(String windowId) {
    final previousZOrder = workspaceController.windowInteractionState.previousWindowZOrders.remove(windowId);
    if (previousZOrder == null) {
      return;
    }

    workspaceController.windows.arrangement.restorePreviousZOrder(activeWorkspace(), windowId, previousZOrder);
  }

  void moveWindow(String windowId, Offset delta) {
    workspaceController.windows.editing.move(activeWorkspace(), windowId, delta);
  }

  void resizeWindow(String windowId, WindowResizeHandle handle, Offset delta) {
    workspaceController.windows.editing.resize(activeWorkspace(), windowId, handle, delta);
  }

  void transformWindowFromTrackpad(String windowId, double scaleDelta, Offset localFocalPoint) {
    workspaceController.windows.editing.transformFromTrackpad(activeWorkspace(), windowId, scaleDelta);
  }

  void fitWindowToContent(String windowId) {
    workspaceController.windows.editing.fitToContent(activeWorkspaceOrNull(), windowId);
  }

  void fitWorkspaceViewportToContent() {
    workspaceController.viewport.fit.toContent(activeWorkspaceOrNull());
  }

  void handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, Workspace workspace) {
    workspaceController.viewport.gesture.handlePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressed(),
      isOptionPressedForWindowGesture: isOptionPressed(),
    );
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    workspaceController.viewport.gesture.handlePanZoomUpdate(event, workspace, viewportSize);
  }

  void handleWorkspacePanZoomEnd() {
    unawaited(workspaceController.viewport.gesture.handlePanZoomEnd());
  }

  int collatableWindowCount() {
    final workspace = activeWorkspaceOrNull();
    if (workspace == null || appUiState.workspaceLayoutMode != WorkspaceLayoutMode.freeform) {
      return 0;
    }

    return workspaceController.windows.arrangement.collatableCount(workspace);
  }

  bool canCollateActiveWorkspace() {
    return workspaceController.windows.arrangement.canCollate(activeWorkspaceOrNull());
  }

  void collateActiveWorkspace() {
    final workspace = activeWorkspaceOrNull();
    if (!workspaceController.windows.arrangement.canCollate(workspace)) {
      return;
    }

    workspaceController.windows.arrangement.collate(workspace!);
  }

  void setWindowZoom(String windowId, WindowZoomUpdate update) {
    workspaceController.windows.editing.setZoom(activeWorkspace(), windowId, update);
  }

  void setVideoPosition(String windowId, int positionMs) {
    workspaceController.playback.workspace.setPosition(activeWorkspaceOrNull(), windowId, positionMs);
  }

  void cycleVideoPlaybackSpeed(String windowId) {
    workspaceController.playback.workspace.cycleSpeed(activeWorkspaceOrNull(), windowId);
  }

  void setWindowIntrinsicSize(String windowId, Size intrinsicSize) {
    workspaceController.windows.editing.setIntrinsicSize(activeWorkspaceOrNull(), windowId, intrinsicSize);
  }

  bool isVideoWindowPaused(String windowId) {
    return workspaceController.playback.runtime.isPaused(windowId);
  }

  void toggleVideoPlayback(String windowId) {
    if (!workspaceController.playback.workspace.canToggle(activeWorkspaceOrNull(), windowId)) {
      return;
    }

    workspaceController.playback.runtime.toggle(windowId);
  }

  void pauseAllVideos() {
    workspaceController.playback.runtime.stopAll(environment());
  }

  void flashWindow(String windowId, {required bool mounted}) {
    workspaceController.windows.runtime.flash(windowId, mounted: mounted);
  }
}

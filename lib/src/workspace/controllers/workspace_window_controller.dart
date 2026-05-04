// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_gesture_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';
import 'package:serenity_viewer/src/window/frame/window_resize_helpers.dart';
import 'package:serenity_viewer/src/window/interaction/window_zoom_update.dart';

class WorkspaceWindowController {
  const WorkspaceWindowController({
    required this.appUiState,
    required this.windowInteractionState,
    required this.environment,
    required this.activeWorkspace,
    required this.activeWorkspaceOrNull,
    required this.gestureController,
    required this.windowsController,
    required this.viewportController,
    required this.playbackController,
  });

  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final Environment? Function() environment;
  final Workspace Function() activeWorkspace;
  final Workspace? Function() activeWorkspaceOrNull;
  final WorkspaceGestureController gestureController;
  final WorkspaceWindowsController windowsController;
  final WorkspaceViewportController viewportController;
  final WorkspacePlaybackController playbackController;

  void setActiveGestureWindow(String? windowId) {
    gestureController.setActive(windowId);
  }

  void setPinnedHoverWindow(String? windowId) {
    gestureController.setPinnedHover(windowId);
  }

  void clearPinnedHoverWindow() {
    setPinnedHoverWindow(null);
  }

  void handleOptionGestureHover(PointerHoverEvent event, Workspace workspace) {
    windowsController.editing.handleOptionHover(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressed(),
      isOptionPressedForWindowGesture: isOptionPressed(),
    );
  }

  void focusWindow(String windowId) {
    final result = windowsController.arrangement.focus(activeWorkspace(), windowId);
    if (result?.previousZOrder != null) {
      windowInteractionState.rememberPreviousWindowZOrder(windowId, result!.previousZOrder!);
    }
  }

  Window? focusedWindowOrNull() {
    return windowsController.arrangement.focusedOrNull(activeWorkspaceOrNull());
  }

  void restorePreviousWindowZOrder(String windowId) {
    final previousZOrder = windowInteractionState.takePreviousWindowZOrder(windowId);
    if (previousZOrder == null) {
      return;
    }

    windowsController.arrangement.restorePreviousZOrder(activeWorkspace(), windowId, previousZOrder);
  }

  void moveWindow(String windowId, Offset delta) {
    windowsController.editing.move(activeWorkspace(), windowId, delta);
  }

  void resizeWindow(String windowId, WindowResizeHandle handle, Offset delta) {
    windowsController.editing.resize(activeWorkspace(), windowId, handle, delta);
  }

  void transformWindowFromTrackpad(String windowId, double scaleDelta, Offset localFocalPoint) {
    windowsController.editing.transformFromTrackpad(activeWorkspace(), windowId, scaleDelta);
  }

  void fitWindowToContent(String windowId) {
    windowsController.editing.fitToContent(activeWorkspaceOrNull(), windowId);
  }

  void fitWorkspaceViewportToContent() {
    viewportController.fit.toContent(activeWorkspaceOrNull());
  }

  void handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, Workspace workspace) {
    viewportController.gesture.handlePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressed(),
      isOptionPressedForWindowGesture: isOptionPressed(),
    );
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    viewportController.gesture.handlePanZoomUpdate(event, workspace, viewportSize);
  }

  void handleWorkspacePanZoomEnd() {
    unawaited(viewportController.gesture.handlePanZoomEnd());
  }

  int collatableWindowCount() {
    final workspace = activeWorkspaceOrNull();
    if (workspace == null || appUiState.workspaceLayoutMode != WorkspaceLayoutMode.freeform) {
      return 0;
    }

    return windowsController.arrangement.collatableCount(workspace);
  }

  bool canCollateActiveWorkspace() {
    return windowsController.arrangement.canCollate(activeWorkspaceOrNull());
  }

  void collateActiveWorkspace() {
    final workspace = activeWorkspaceOrNull();
    if (!windowsController.arrangement.canCollate(workspace)) {
      return;
    }

    windowsController.arrangement.collate(workspace!);
  }

  void setWindowZoom(String windowId, WindowZoomUpdate update) {
    windowsController.editing.setZoom(activeWorkspace(), windowId, update);
  }

  void setVideoPosition(String windowId, int positionMs) {
    playbackController.workspace.setPosition(activeWorkspaceOrNull(), windowId, positionMs);
  }

  void cycleVideoPlaybackSpeed(String windowId) {
    playbackController.workspace.cycleSpeed(activeWorkspaceOrNull(), windowId);
  }

  void setWindowIntrinsicSize(String windowId, Size intrinsicSize) {
    windowsController.editing.setIntrinsicSize(activeWorkspaceOrNull(), windowId, intrinsicSize);
  }

  bool isVideoWindowPaused(String windowId) {
    return playbackController.runtime.isPaused(windowId);
  }

  void toggleVideoPlayback(String windowId) {
    if (!playbackController.workspace.canToggle(activeWorkspaceOrNull(), windowId)) {
      return;
    }

    playbackController.runtime.toggle(windowId);
  }

  void pauseAllVideos() {
    playbackController.runtime.stopAll(environment());
  }

  void flashWindow(String windowId, {required bool mounted}) {
    windowsController.runtime.flash(windowId, mounted: mounted);
  }
}

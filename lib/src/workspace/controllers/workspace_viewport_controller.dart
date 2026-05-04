import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_fit_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_gesture_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceViewportController {
  WorkspaceViewportController({
    required this.environmentStoreState,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.thumbnailController,
    required this.replaceWorkspace,
    required this.activeWorkspaceOrNull,
    required this.refreshActiveWorkspaceThumbnail,
    required this.transformWindowFromTrackpad,
  }) {
    gesture = WorkspaceViewportGestureController(
      appUiState: appUiState,
      windowInteractionState: windowInteractionState,
      workspaceViewportState: workspaceViewportState,
      setWorkspaceViewport: setWorkspaceViewport,
      refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
    );
    fit = WorkspaceViewportFitController(
      workspaceViewportState: workspaceViewportState,
      replaceWorkspace: replaceWorkspace,
      setWorkspaceViewport: setWorkspaceViewport,
    );
  }

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailController thumbnailController;
  final SerenityWorkspaceReplace replaceWorkspace;
  final Workspace? Function() activeWorkspaceOrNull;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final void Function(String windowId, double scaleDelta, Offset globalPointerPosition) transformWindowFromTrackpad;
  late final WorkspaceViewportGestureController gesture;
  late final WorkspaceViewportFitController fit;
  bool _isWindowTrackpadGestureActive = false;
  double _lastWindowTrackpadScale = 1.0;

  void fitWorkspaceViewportToContent() {
    fit.toContent(activeWorkspaceOrNull());
  }

  void handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, Workspace workspace) {
    final activeGestureWindowId = windowInteractionState.activeGestureWindowId;
    if (isOptionPressed() && activeGestureWindowId != null) {
      _isWindowTrackpadGestureActive = true;
      _lastWindowTrackpadScale = 1.0;
      workspaceViewportState.setGestureInactive();
      return;
    }

    gesture.handlePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressed(),
      isOptionPressedForWindowGesture: isOptionPressed(),
    );
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    if (_isWindowTrackpadGestureActive) {
      final activeGestureWindowId = windowInteractionState.activeGestureWindowId;
      if (activeGestureWindowId == null) {
        _isWindowTrackpadGestureActive = false;
        _lastWindowTrackpadScale = 1.0;
        return;
      }

      final scaleDelta = event.scale / _lastWindowTrackpadScale;
      _lastWindowTrackpadScale = event.scale;
      transformWindowFromTrackpad(activeGestureWindowId, scaleDelta, event.position);
      return;
    }

    gesture.handlePanZoomUpdate(event, workspace, viewportSize);
  }

  void handleWorkspacePanZoomEnd() {
    if (_isWindowTrackpadGestureActive) {
      _isWindowTrackpadGestureActive = false;
      _lastWindowTrackpadScale = 1.0;
      return;
    }

    unawaited(gesture.handlePanZoomEnd());
  }

  void setWorkspaceViewport({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) {
    final environment = environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    final workspace = environment.workspaces.where((entry) => entry.id == workspaceId).firstOrNull;
    if (workspace == null) {
      return;
    }

    final nextWorkspace = WorkspaceLayout.setWorkspaceViewport(
      workspace,
      viewportSize: workspaceViewportState.viewportSize,
      center: center,
      zoom: zoom,
    );
    final viewportChanged =
        (workspace.viewportCenter.dx - nextWorkspace.viewportCenter.dx).abs() > 0.001 ||
        (workspace.viewportCenter.dy - nextWorkspace.viewportCenter.dy).abs() > 0.001 ||
        (workspace.viewportZoom - nextWorkspace.viewportZoom).abs() > 0.001;
    if (!viewportChanged) {
      return;
    }

    replaceWorkspace(nextWorkspace, queueThumbnail: queueThumbnail);
    if (!queueThumbnail) {
      thumbnailController.markWorkspaceDirty(workspaceId);
    }
  }
}

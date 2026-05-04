import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceViewportGestureController {
  const WorkspaceViewportGestureController({
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.setWorkspaceViewport,
    required this.refreshActiveWorkspaceThumbnail,
  });

  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;

  void handlePanZoomStart(
    PointerPanZoomStartEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    if (appUiState.screen != SerenityScreen.workspace ||
        appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose ||
        windowInteractionState.pinnedHoverWindowId != null ||
        isCommandPressedForContentGesture ||
        isOptionPressedForWindowGesture) {
      workspaceViewportState.setGestureInactive();
      return;
    }

    workspaceViewportState.startGesture(
      center: workspace.viewportCenter,
      zoom: workspace.viewportZoom,
      localFocalPoint: event.localPosition,
    );
  }

  void handlePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    if (!workspaceViewportState.isGestureActive) {
      return;
    }

    workspaceViewportState.accumulateGesturePan(event.panDelta);
    final nextZoom = WorkspaceLayout.clampWorkspaceZoom(
      workspaceViewportState.gestureStartZoom * math.pow(event.scale, 1.15).toDouble(),
    );
    final viewportCenter = viewportSize.center(Offset.zero);
    final anchorWorldPoint =
        workspaceViewportState.gestureStartCenter +
        ((workspaceViewportState.gestureStartLocalFocalPoint - viewportCenter) /
            workspaceViewportState.gestureStartZoom);
    final nextAnchorLocalPoint =
        workspaceViewportState.gestureStartLocalFocalPoint + workspaceViewportState.gestureAccumulatedPan;
    final nextCenter = WorkspaceLayout.clampWorkspaceCenter(
      center: anchorWorldPoint - ((nextAnchorLocalPoint - viewportCenter) / nextZoom),
      zoom: nextZoom,
      viewportSize: viewportSize,
    );
    setWorkspaceViewport(workspaceId: workspace.id, center: nextCenter, zoom: nextZoom, queueThumbnail: false);
  }

  Future<void> handlePanZoomEnd() async {
    workspaceViewportState.endGesture();
    await refreshActiveWorkspaceThumbnail();
  }
}

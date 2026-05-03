import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceViewportControllerState {
  WorkspaceViewportControllerState({
    required this.chromeState,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.replaceWorkspace,
    required this.setWorkspaceViewport,
    required this.refreshActiveWorkspaceThumbnail,
  });

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;

  void handleWorkspacePanZoomStart(
    PointerPanZoomStartEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    if (chromeState.screen != SerenityScreen.workspace ||
        chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose ||
        windowInteractionState.pinnedHoverWindowId != null ||
        isCommandPressedForContentGesture ||
        isOptionPressedForWindowGesture) {
      workspaceViewportState.isGestureActive = false;
      return;
    }

    workspaceViewportState.isGestureActive = true;
    workspaceViewportState.gestureStartCenter = workspace.viewportCenter;
    workspaceViewportState.gestureStartZoom = workspace.viewportZoom;
    workspaceViewportState.gestureStartLocalFocalPoint = event.localPosition;
    workspaceViewportState.gestureAccumulatedPan = Offset.zero;
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    if (!workspaceViewportState.isGestureActive) {
      return;
    }

    workspaceViewportState.gestureAccumulatedPan += event.panDelta;
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

  Future<void> handleWorkspacePanZoomEnd() async {
    workspaceViewportState.isGestureActive = false;
    workspaceViewportState.gestureAccumulatedPan = Offset.zero;
    await refreshActiveWorkspaceThumbnail();
  }

  void fitWorkspaceViewportToContent(Workspace? workspace) {
    if (workspace == null) {
      return;
    }

    if (workspaceViewportState.viewportSize.width <= 0 ||
        workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      setWorkspaceViewport(workspaceId: workspace.id, center: defaultWorkspaceCenter, zoom: 1, queueThumbnail: true);
      return;
    }

    replaceWorkspace(
      WorkspaceLayout.fitWorkspaceViewportToContent(workspace, workspaceViewportState.viewportSize),
      queueThumbnail: true,
    );
  }
}

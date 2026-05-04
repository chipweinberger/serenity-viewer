import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
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
    required SerenityWorkspaceViewportSetter applyWorkspaceViewport,
    required this.refreshActiveWorkspaceThumbnail,
  }) : gesture = WorkspaceViewportGestureController(
         appUiState: appUiState,
         windowInteractionState: windowInteractionState,
         workspaceViewportState: workspaceViewportState,
         setWorkspaceViewport: applyWorkspaceViewport,
         refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
       ),
       fit = WorkspaceViewportFitController(
         workspaceViewportState: workspaceViewportState,
         replaceWorkspace: replaceWorkspace,
         setWorkspaceViewport: applyWorkspaceViewport,
       );

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailController thumbnailController;
  final SerenityWorkspaceReplace replaceWorkspace;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final WorkspaceViewportGestureController gesture;
  final WorkspaceViewportFitController fit;

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

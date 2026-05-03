import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppShellWorkspaceGeometryController {
  const AppShellWorkspaceGeometryController({
    required this.persistenceState,
    required this.workspaceViewportState,
    required this.thumbnailController,
    required this.replaceWorkspace,
  });

  final AppEnvironmentState persistenceState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailController thumbnailController;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;

  String newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(9999)}';
  }

  int colorFromDigest(String value) {
    return assetColorFromMd5(value).toARGB32();
  }

  void setWorkspaceViewport({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) {
    final environment = persistenceState.environment;
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

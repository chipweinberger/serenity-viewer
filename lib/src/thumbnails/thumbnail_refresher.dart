import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/app_environment_state.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_store.dart';

class ThumbnailRefresher {
  ThumbnailRefresher({
    required this.persistenceState,
    required this.environmentController,
    required this.renderer,
    required this.store,
  });

  final AppEnvironmentState persistenceState;
  final EnvironmentController environmentController;
  final ThumbnailRenderer renderer;
  final ThumbnailStore store;

  Future<bool> refreshWorkspace(String workspaceId, {required Size viewportSize}) async {
    final environment = persistenceState.environment;
    if (environment == null) {
      return false;
    }

    final workspaceMatches = environment.workspaces.where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return false;
    }

    final workspace = workspaceMatches.first;
    final bytes = await renderer.buildThumbnailBytes(workspace: workspace, viewportSize: viewportSize);
    if (bytes == null) {
      return false;
    }

    final thumbnailPath = await store.persistThumbnail(workspaceId: workspaceId, bytes: bytes);
    final freshEnvironment = persistenceState.environment;
    if (freshEnvironment == null) {
      return false;
    }

    final currentMatching = freshEnvironment.workspaces.where((entry) => entry.id == workspaceId);
    if (currentMatching.isEmpty) {
      return false;
    }

    final currentWorkspace = currentMatching.first;
    final nextEnvironment = freshEnvironment.copyWith(
      workspaces: freshEnvironment.workspaces
          .map(
            (entry) => entry.id == workspaceId
                ? entry.copyWith(thumbnailPath: thumbnailPath, thumbnailVersion: currentWorkspace.thumbnailVersion + 1)
                : entry,
          )
          .toList(),
    );
    environmentController.updateEnvironment(nextEnvironment);
    return true;
  }
}

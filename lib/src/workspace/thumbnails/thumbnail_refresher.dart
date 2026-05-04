import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';

typedef ThumbnailEnvironmentUpdater = void Function(Environment nextEnvironment);

class ThumbnailRefresher {
  ThumbnailRefresher({
    required this.environmentStoreState,
    required this.updateEnvironment,
    required this.renderer,
    required this.store,
  });

  final EnvironmentStoreState environmentStoreState;
  final ThumbnailEnvironmentUpdater updateEnvironment;
  final ThumbnailRenderer renderer;
  final ThumbnailStore store;

  Future<bool> refreshWorkspace(String workspaceId, {required Size viewportSize}) async {
    final environment = environmentStoreState.environment;
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
    final freshEnvironment = environmentStoreState.environment;
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
    updateEnvironment(nextEnvironment);
    return true;
  }
}

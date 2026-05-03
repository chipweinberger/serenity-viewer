import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environments/persistence/workspace_thumbnail_renderer.dart';
import 'package:serenity_viewer/src/environments/persistence/workspace_thumbnail_store.dart';
import 'package:serenity_viewer/src/environments/session/session_controller.dart';
import 'package:serenity_viewer/src/environments/session/shell_persistence_state.dart';

class WorkspaceThumbnailRefresher {
  WorkspaceThumbnailRefresher({
    required this.persistenceState,
    required this.sessionController,
    required this.renderer,
    required this.store,
  });

  final ShellPersistenceState persistenceState;
  final SessionController sessionController;
  final WorkspaceThumbnailRenderer renderer;
  final WorkspaceThumbnailStore store;

  Future<bool> refreshWorkspace(String workspaceId, {required Size viewportSize}) async {
    final session = persistenceState.session;
    if (session == null) {
      return false;
    }

    final workspaceMatches = session.workspaces.where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return false;
    }

    final workspace = workspaceMatches.first;
    final bytes = await renderer.buildWorkspaceThumbnailBytes(workspace: workspace, viewportSize: viewportSize);
    if (bytes == null) {
      return false;
    }

    final thumbnailPath = await store.persistThumbnail(workspaceId: workspaceId, bytes: bytes);
    final freshSession = persistenceState.session;
    if (freshSession == null) {
      return false;
    }

    final currentMatching = freshSession.workspaces.where((entry) => entry.id == workspaceId);
    if (currentMatching.isEmpty) {
      return false;
    }

    final currentWorkspace = currentMatching.first;
    final nextSession = freshSession.copyWith(
      workspaces: freshSession.workspaces
          .map(
            (entry) => entry.id == workspaceId
                ? entry.copyWith(thumbnailPath: thumbnailPath, thumbnailVersion: currentWorkspace.thumbnailVersion + 1)
                : entry,
          )
          .toList(),
    );
    sessionController.updateSession(nextSession);
    return true;
  }
}

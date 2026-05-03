import 'dart:io';

import 'package:serenity_viewer/src/sry_document/models/session_state.dart';
import 'package:serenity_viewer/src/sry_document/models/workspace_window_state.dart';
import 'package:serenity_viewer/src/sry_document/models/workspace_state.dart';

class SessionBookmarkSynchronizer {
  SessionBookmarkSynchronizer({required this.createFileBookmark});

  final Future<String?> Function(String path) createFileBookmark;

  Future<SessionState> synchronize(SessionState session) async {
    var changed = false;
    final nextWorkspaces = <WorkspaceState>[];

    for (final workspace in session.workspaces) {
      var workspaceChanged = false;
      final nextWindows = <WorkspaceWindowState>[];

      for (final window in workspace.windows) {
        final asset = window.asset;
        final path = asset.filePath;
        if (path == null || path.isEmpty || asset.fileBookmark != null && asset.fileBookmark!.isNotEmpty) {
          nextWindows.add(window);
          continue;
        }

        if (!await File(path).exists()) {
          nextWindows.add(window);
          continue;
        }

        final bookmark = await createFileBookmark(path);
        if (bookmark == null || bookmark.isEmpty) {
          nextWindows.add(window);
          continue;
        }

        changed = true;
        workspaceChanged = true;
        nextWindows.add(window.copyWith(asset: asset.copyWith(fileBookmark: bookmark)));
      }

      nextWorkspaces.add(workspaceChanged ? workspace.copyWith(windows: nextWindows) : workspace);
    }

    if (!changed) {
      return session;
    }

    return session.copyWith(workspaces: nextWorkspaces);
  }
}

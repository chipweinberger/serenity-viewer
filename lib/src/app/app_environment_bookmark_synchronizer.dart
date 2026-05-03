import 'dart:io';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

class EnvironmentBookmarkSynchronizer {
  EnvironmentBookmarkSynchronizer({required this.createFileBookmark});

  final Future<String?> Function(String path) createFileBookmark;

  Future<Environment> synchronize(Environment environment) async {
    var changed = false;
    final nextWorkspaces = <Workspace>[];

    for (final workspace in environment.workspaces) {
      var workspaceChanged = false;
      final nextWindows = <Window>[];

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
      return environment;
    }

    return environment.copyWith(workspaces: nextWorkspaces);
  }
}

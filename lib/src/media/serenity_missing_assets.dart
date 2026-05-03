// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellMissingAssets on _SerenityShellState {
  Future<String?> _locateFile({
    required String filename,
    required String? originalPath,
    required List<String> rankedFolders,
  }) async {
    final candidates = <String>[];
    if (originalPath != null && originalPath.isNotEmpty) {
      candidates.add(File(originalPath).parent.path);
    }
    candidates.addAll(rankedFolders);

    for (final folder in candidates) {
      final candidate = File('$folder${Platform.pathSeparator}$filename');
      if (await candidate.exists()) {
        return candidate.path;
      }
    }

    return null;
  }

  Future<SerenitySessionState> _resolveMissingAssets(SerenitySessionState session) async {
    final rankedFolders = [...session.knownFolders];
    rankedFolders.sort((a, b) => (session.folderPopularity[b] ?? 0).compareTo(session.folderPopularity[a] ?? 0));

    var nextSession = session;
    var changed = false;

    final nextWorkspaces = <WorkspaceState>[];
    for (final workspace in session.workspaces) {
      final nextWindows = <AssetWindowState>[];
      for (final window in workspace.windows) {
        final path = window.asset.filePath;
        if (path == null || path.isEmpty) {
          nextWindows.add(window);
          continue;
        }

        if (await File(path).exists()) {
          final actualFilename = File(path).uri.pathSegments.isEmpty
              ? window.asset.filename
              : File(path).uri.pathSegments.last;
          if (actualFilename == window.asset.filename) {
            nextWindows.add(window);
          } else {
            changed = true;
            nextWindows.add(window.copyWith(asset: window.asset.copyWith(filename: actualFilename)));
          }
          continue;
        }

        final bookmark = window.asset.fileBookmark;
        if (bookmark != null && bookmark.isNotEmpty) {
          final resolvedFromBookmark = await _resolveFileBookmark(bookmark);
          if (resolvedFromBookmark != null && resolvedFromBookmark.isNotEmpty) {
            final resolvedFile = File(resolvedFromBookmark);
            if (await resolvedFile.exists()) {
              final actualFilename = resolvedFile.uri.pathSegments.isEmpty
                  ? window.asset.filename
                  : resolvedFile.uri.pathSegments.last;
              nextWindows.add(
                window.copyWith(
                  asset: window.asset.copyWith(filePath: resolvedFromBookmark, filename: actualFilename),
                ),
              );
              changed = true;
              continue;
            }
          }
        }

        final resolvedPath = await _locateFile(
          filename: window.asset.filename,
          originalPath: path,
          rankedFolders: rankedFolders,
        );

        if (resolvedPath == null) {
          nextWindows.add(window);
          continue;
        }

        final folder = File(resolvedPath).parent.path;
        final nextKnownFolders = [...nextSession.knownFolders];
        if (!nextKnownFolders.contains(folder)) {
          nextKnownFolders.add(folder);
        }

        final nextPopularity = Map<String, int>.from(nextSession.folderPopularity);
        nextPopularity[folder] = (nextPopularity[folder] ?? 0) + 1;

        nextSession = nextSession.copyWith(knownFolders: nextKnownFolders, folderPopularity: nextPopularity);
        changed = true;
        final refreshedBookmark = await _createFileBookmark(resolvedPath);
        final actualFilename = File(resolvedPath).uri.pathSegments.isEmpty
            ? window.asset.filename
            : File(resolvedPath).uri.pathSegments.last;
        nextWindows.add(
          window.copyWith(
            asset: window.asset.copyWith(
              filePath: resolvedPath,
              fileBookmark: refreshedBookmark ?? window.asset.fileBookmark,
              filename: actualFilename,
            ),
          ),
        );
      }

      nextWorkspaces.add(workspace.copyWith(windows: nextWindows));
    }

    if (!changed) {
      return nextSession;
    }

    return nextSession.copyWith(workspaces: nextWorkspaces);
  }
}

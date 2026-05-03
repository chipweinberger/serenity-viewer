import 'dart:io';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

typedef BookmarkResolver = Future<String?> Function(String bookmark);
typedef BookmarkCreator = Future<String?> Function(String path);

Future<String?> locateMissingAssetFile({
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

Future<Environment> resolveMissingAssetsInEnvironment({
  required Environment environment,
  required BookmarkResolver resolveBookmark,
  required BookmarkCreator createBookmark,
}) async {
  final rankedFolders = [...environment.knownFolders];
  rankedFolders.sort((a, b) => (environment.folderPopularity[b] ?? 0).compareTo(environment.folderPopularity[a] ?? 0));

  var nextEnvironment = environment;
  var changed = false;

  final nextWorkspaces = <Workspace>[];
  for (final workspace in environment.workspaces) {
    final nextWindows = <Window>[];
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
        final resolvedFromBookmark = await resolveBookmark(bookmark);
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

      final resolvedPath = await locateMissingAssetFile(
        filename: window.asset.filename,
        originalPath: path,
        rankedFolders: rankedFolders,
      );

      if (resolvedPath == null) {
        nextWindows.add(window);
        continue;
      }

      final folder = File(resolvedPath).parent.path;
      final nextKnownFolders = [...nextEnvironment.knownFolders];
      if (!nextKnownFolders.contains(folder)) {
        nextKnownFolders.add(folder);
      }

      final nextPopularity = Map<String, int>.from(nextEnvironment.folderPopularity);
      nextPopularity[folder] = (nextPopularity[folder] ?? 0) + 1;

      nextEnvironment = nextEnvironment.copyWith(knownFolders: nextKnownFolders, folderPopularity: nextPopularity);
      changed = true;
      final refreshedBookmark = await createBookmark(resolvedPath);
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
    return nextEnvironment;
  }

  return nextEnvironment.copyWith(workspaces: nextWorkspaces);
}

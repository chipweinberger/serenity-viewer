import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/media/loading/workspace_media_counts.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

MediaLoadPlan buildWorkspaceLoadPlan({required Environment environment, required Workspace? activeWorkspace}) {
  final loadedAssetIds = <String>{};
  var loadedImages = 0;
  var loadedShortVideos = 0;
  var loadedLongVideos = 0;

  void retainWindow(Window window) {
    if (!loadedAssetIds.add(window.asset.id)) {
      return;
    }

    switch (window.asset.type) {
      case AssetType.image:
        loadedImages += 1;
        break;
      case AssetType.video:
        if (window.asset.videoLengthCategory == VideoLengthCategory.short) {
          loadedShortVideos += 1;
        } else {
          loadedLongVideos += 1;
        }
        break;
    }
  }

  if (activeWorkspace == null) {
    return const MediaLoadPlan(loadedAssetIds: {}, loadedImages: 0, loadedShortVideos: 0, loadedLongVideos: 0);
  }

  final activeWorkspaceId = activeWorkspace.id;
  for (final window in activeWorkspace.windows) {
    retainWindow(window);
  }

  final hiddenWorkspaces = environment.workspaces.where((workspace) => workspace.id != activeWorkspaceId).toList()
    ..sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));

  for (final workspace in hiddenWorkspaces) {
    for (final window in workspace.windows) {
      if (window.asset.type == AssetType.image) {
        if (loadedImages >= environment.imageLoadLimit) {
          continue;
        }
        retainWindow(window);
        continue;
      }

      if (window.asset.videoLengthCategory == VideoLengthCategory.short) {
        if (loadedShortVideos >= environment.shortVideoLoadLimit) {
          continue;
        }
        retainWindow(window);
        continue;
      }

      if (loadedLongVideos >= environment.longVideoLoadLimit) {
        continue;
      }
      retainWindow(window);
    }
  }

  return MediaLoadPlan(
    loadedAssetIds: loadedAssetIds,
    loadedImages: loadedImages,
    loadedShortVideos: loadedShortVideos,
    loadedLongVideos: loadedLongVideos,
  );
}

int unloadedWorkspaceWindowCount(Workspace workspace, MediaLoadPlan loadPlan) {
  return workspace.windows.where((window) => !loadPlan.loadedAssetIds.contains(window.asset.id)).length;
}

WorkspaceMediaCounts workspaceMediaCounts(Workspace workspace) {
  return WorkspaceMediaCounts(
    images: workspace.windows.where((window) => window.asset.type == AssetType.image).length,
    shortVideos: workspace.windows
        .where((window) => window.asset.videoLengthCategory == VideoLengthCategory.short)
        .length,
    longVideos: workspace.windows
        .where((window) => window.asset.videoLengthCategory == VideoLengthCategory.long)
        .length,
    links: workspace.links.length,
  );
}

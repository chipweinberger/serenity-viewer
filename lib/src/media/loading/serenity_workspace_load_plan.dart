import 'package:serenity_viewer/src/foundation/serenity_core.dart';
import 'package:serenity_viewer/src/workspace/windows/asset_window_state.dart';
import 'package:serenity_viewer/src/media/loading/serenity_load_plan.dart';
import 'package:serenity_viewer/src/environments/session/serenity_session_state.dart';
import 'package:serenity_viewer/src/media/assets/workspace_media_counts.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';

SerenityLoadPlan buildWorkspaceLoadPlan({
  required SerenitySessionState session,
  required WorkspaceState? activeWorkspace,
}) {
  final loadedAssetIds = <String>{};
  var loadedImages = 0;
  var loadedShortVideos = 0;
  var loadedLongVideos = 0;

  void retainWindow(AssetWindowState window) {
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
    return const SerenityLoadPlan(loadedAssetIds: {}, loadedImages: 0, loadedShortVideos: 0, loadedLongVideos: 0);
  }

  final activeWorkspaceId = activeWorkspace.id;
  for (final window in activeWorkspace.windows) {
    retainWindow(window);
  }

  final hiddenWorkspaces = session.workspaces.where((workspace) => workspace.id != activeWorkspaceId).toList()
    ..sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));

  for (final workspace in hiddenWorkspaces) {
    for (final window in workspace.windows) {
      if (window.asset.type == AssetType.image) {
        if (loadedImages >= session.imageLoadLimit) {
          continue;
        }
        retainWindow(window);
        continue;
      }

      if (window.asset.videoLengthCategory == VideoLengthCategory.short) {
        if (loadedShortVideos >= session.shortVideoLoadLimit) {
          continue;
        }
        retainWindow(window);
        continue;
      }

      if (loadedLongVideos >= session.longVideoLoadLimit) {
        continue;
      }
      retainWindow(window);
    }
  }

  return SerenityLoadPlan(
    loadedAssetIds: loadedAssetIds,
    loadedImages: loadedImages,
    loadedShortVideos: loadedShortVideos,
    loadedLongVideos: loadedLongVideos,
  );
}

int unloadedWorkspaceWindowCount(WorkspaceState workspace, SerenityLoadPlan loadPlan) {
  return workspace.windows.where((window) => !loadPlan.loadedAssetIds.contains(window.asset.id)).length;
}

WorkspaceMediaCounts workspaceMediaCounts(WorkspaceState workspace) {
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

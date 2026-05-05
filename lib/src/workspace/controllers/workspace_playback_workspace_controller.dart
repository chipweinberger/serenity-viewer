import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/mutations/workspace_playback_mutations.dart';

import 'workspace_controller.dart';

class WorkspacePlaybackWorkspaceController {
  const WorkspacePlaybackWorkspaceController({required this.replaceWorkspace});

  final SerenityWorkspaceReplace replaceWorkspace;

  void setPosition(Workspace? workspace, String windowId, int positionMs) {
    if (workspace == null) {
      return;
    }

    final currentWindow = workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
    if (currentWindow == null || currentWindow.videoPositionMs == positionMs) {
      return;
    }

    replaceWorkspace(
      WorkspacePlaybackMutations.setVideoPosition(workspace, windowId, positionMs),
      queueThumbnail: false,
    );
  }

  void setPositions(Workspace? workspace, Map<String, int> positionsByWindowId) {
    if (workspace == null || positionsByWindowId.isEmpty) {
      return;
    }

    final nextPositions = <String, int>{};
    final windowsById = {for (final window in workspace.windows) window.asset.id: window};
    for (final entry in positionsByWindowId.entries) {
      final currentWindow = windowsById[entry.key];
      if (currentWindow == null || currentWindow.videoPositionMs == entry.value) {
        continue;
      }
      nextPositions[entry.key] = entry.value;
    }

    if (nextPositions.isEmpty) {
      return;
    }

    replaceWorkspace(WorkspacePlaybackMutations.setVideoPositions(workspace, nextPositions), queueThumbnail: false);
  }

  void clearPosition(Workspace? workspace, String windowId) {
    if (workspace == null) {
      return;
    }

    final currentWindow = workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
    if (currentWindow == null || currentWindow.videoPositionMs == null) {
      return;
    }

    replaceWorkspace(WorkspacePlaybackMutations.clearVideoPosition(workspace, windowId), queueThumbnail: false);
  }

  void cycleSpeed(Workspace? workspace, String windowId) {
    if (workspace == null ||
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isEmpty) {
      return;
    }

    replaceWorkspace(WorkspacePlaybackMutations.cycleVideoPlaybackSpeed(workspace, windowId), queueThumbnail: false);
  }

  bool canToggle(Workspace? workspace, String windowId) {
    return workspace != null &&
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isNotEmpty;
  }
}

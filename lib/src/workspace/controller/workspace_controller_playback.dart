part of 'workspace_controller.dart';

class _WorkspacePlaybackController {
  _WorkspacePlaybackController({required this.replaceWorkspace});

  final SerenityWorkspaceReplace replaceWorkspace;

  void setVideoPosition(Workspace? workspace, String windowId, int positionMs) {
    if (workspace == null) {
      return;
    }

    final currentWindow = workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
    if (currentWindow == null || currentWindow.videoPositionMs == positionMs) {
      return;
    }

    replaceWorkspace(
      WorkspacePlaybackOperations.setVideoPosition(workspace, windowId, positionMs),
      queueThumbnail: false,
    );
  }

  void cycleVideoPlaybackSpeed(Workspace? workspace, String windowId) {
    if (workspace == null ||
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isEmpty) {
      return;
    }

    replaceWorkspace(WorkspacePlaybackOperations.cycleVideoPlaybackSpeed(workspace, windowId), queueThumbnail: false);
  }
}

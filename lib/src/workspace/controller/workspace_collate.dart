part of 'workspace_controller.dart';

const Size workspaceCollateTargetBox = Size(700, 700);

extension WorkspaceControllerCollate on WorkspaceController {
  bool canCollateWorkspaceWindows(Workspace? workspace) {
    return workspace != null &&
        chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose &&
        workspace.windows.any((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video);
  }

  int collatableWindowCount(Workspace workspace) {
    return workspace.windows
        .where((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video)
        .length;
  }

  void collateWorkspaceWindows(Workspace workspace) {
    replaceWorkspace(
      WorkspaceLayout.collateWorkspaceWindows(workspace, targetBox: workspaceCollateTargetBox),
      queueThumbnail: true,
    );
  }
}

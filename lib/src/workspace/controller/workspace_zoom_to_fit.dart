part of 'workspace_controller.dart';

extension WorkspaceControllerZoomToFit on WorkspaceController {
  void fitWorkspaceViewportToContent(Workspace? workspace) {
    if (workspace == null) {
      return;
    }

    if (workspaceViewportState.viewportSize.width <= 0 ||
        workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      setWorkspaceViewport(workspaceId: workspace.id, center: defaultWorkspaceCenter, zoom: 1, queueThumbnail: true);
      return;
    }

    replaceWorkspace(
      WorkspaceLayout.fitWorkspaceViewportToContent(workspace, workspaceViewportState.viewportSize),
      queueThumbnail: true,
    );
  }
}

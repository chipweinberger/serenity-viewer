part of 'workspace_controller.dart';

class WorkspaceEnvironmentControllerState {
  bool canMoveSelectedWindowsToWorkspace({
    required Environment? environment,
    required Workspace? sourceWorkspace,
    required String destinationWorkspaceId,
    required bool hasSelectedWindowIds,
  }) {
    return environment != null &&
        sourceWorkspace != null &&
        hasSelectedWindowIds &&
        destinationWorkspaceId != sourceWorkspace.id;
  }

  void toggleWorkspaceOpen(Environment environment, String workspaceId, void Function(Environment) updateEnvironment) {
    updateEnvironment(WorkspaceEnvironmentOperations.toggleWorkspaceOpen(environment, workspaceId));
  }

  void reorderOpenWorkspace(
    Environment? environment,
    List<Workspace> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required void Function(Environment) updateEnvironment,
  }) {
    if (environment == null || sourceWorkspaceId == targetWorkspaceId) {
      return;
    }

    updateEnvironment(
      environment.copyWith(
        workspaces: WorkspaceEnvironmentOperations.reorderOpenWorkspaces(
          workspaces,
          sourceWorkspaceId: sourceWorkspaceId,
          targetWorkspaceId: targetWorkspaceId,
        ),
      ),
    );
  }

  void moveSelectedExposeWindowsToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
    required Set<String> selectedWindowIds,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
    required VoidCallback clearExposeSelection,
  }) {
    updateEnvironment(
      WorkspaceEnvironmentOperations.moveSelectedWindowsToWorkspace(
        environment,
        sourceWorkspaceId: sourceWorkspace.id,
        destinationWorkspaceId: destinationWorkspace.id,
        selectedWindowIds: selectedWindowIds,
      ),
    );
    queueThumbnailRefresh(sourceWorkspace.id, delay: Duration.zero);
    queueThumbnailRefresh(destinationWorkspace.id, delay: Duration.zero);
    clearExposeSelection();
  }
}

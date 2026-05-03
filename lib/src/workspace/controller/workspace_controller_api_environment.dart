import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';

class WorkspaceEnvironmentApi {
  WorkspaceEnvironmentApi(this._controller);

  final WorkspaceController _controller;

  void toggleWorkspaceOpen(Environment environment, String workspaceId, void Function(Environment) updateEnvironment) {
    _controller.environmentController.toggleWorkspaceOpen(environment, workspaceId, updateEnvironment);
  }

  void reorderOpenWorkspace(
    Environment? environment,
    List<Workspace> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required void Function(Environment) updateEnvironment,
  }) {
    _controller.environmentController.reorderOpenWorkspace(
      environment,
      workspaces,
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      updateEnvironment: updateEnvironment,
    );
  }

  bool canMoveSelectedWindowsToWorkspace({
    required Environment? environment,
    required Workspace? sourceWorkspace,
    required String destinationWorkspaceId,
  }) {
    return _controller.environmentController.canMoveSelectedWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
      hasSelectedWindowIds: _controller.windowInteractionState.selectedExposeWindowIds.isNotEmpty,
    );
  }

  void moveSelectedExposeWindowsToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
  }) {
    _controller.environmentController.moveSelectedExposeWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
      selectedWindowIds: _controller.windowInteractionState.selectedExposeWindowIds,
      updateEnvironment: updateEnvironment,
      queueThumbnailRefresh: queueThumbnailRefresh,
      clearExposeSelection: _controller.expose.clearWindowSelection,
    );
  }
}

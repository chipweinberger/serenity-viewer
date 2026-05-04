import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_management_dialogs.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_management_mutations.dart';

class WorkspaceShellManagementApi {
  WorkspaceShellManagementApi(this._controller)
    : dialogs = WorkspaceShellManagementDialogs(context: _controller.context, mounted: _controller.mounted),
      _mutations = WorkspaceShellManagementMutations(_controller);

  final WorkspaceShellController _controller;
  final WorkspaceShellManagementDialogs dialogs;
  final WorkspaceShellManagementMutations _mutations;

  void create() {
    _mutations.create();
  }

  void toggleOpen(String workspaceId) {
    _mutations.toggleOpen(workspaceId);
  }

  void reorderOpen(String sourceWorkspaceId, String targetWorkspaceId) {
    _mutations.reorderOpen(sourceWorkspaceId, targetWorkspaceId);
  }

  Future<void> renameWorkspace(String workspaceId) async {
    final workspaceMatches = _controller.workspaces().where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final trimmedName = await dialogs.promptWorkspaceRename(workspace);
    if (trimmedName == null || trimmedName.isEmpty || trimmedName == workspace.name) {
      return;
    }

    _mutations.rename(workspace, trimmedName);
  }

  Future<void> confirmDeleteWorkspace(String workspaceId) async {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final workspaceMatches = environment.workspaces.where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final shouldDelete = await dialogs.confirmWorkspaceDeletion(workspace);
    if (shouldDelete) {
      _mutations.delete(workspaceId);
    }
  }

  Future<void> moveSelectedExposeWindowsToWorkspace(String destinationWorkspaceId) async {
    final environment = _controller.persistenceState.environment;
    final sourceWorkspace = _controller.activeWorkspace();
    if (!_controller.workspaceController.environment.windowTransfer.canMoveSelectedToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
      hasSelectedWindowIds: _controller.workspaceController.expose.hasSelection(),
    )) {
      if (sourceWorkspace != null && destinationWorkspaceId == sourceWorkspace.id) {
        _controller.showMessage('Choose a different tab to move those windows.');
      }
      return;
    }

    if (sourceWorkspace == null || environment == null) {
      return;
    }

    if (destinationWorkspaceId == sourceWorkspace.id) {
      _controller.showMessage('Choose a different tab to move those windows.');
      return;
    }

    final destinationMatches = environment.workspaces.where((workspace) => workspace.id == destinationWorkspaceId);
    if (destinationMatches.isEmpty) {
      return;
    }

    final destinationWorkspace = destinationMatches.first;
    final selectedWindowCount = _controller.workspaceController.expose.countIn(sourceWorkspace);
    if (selectedWindowCount == 0) {
      _controller.navigation.clearExposeSelection();
      return;
    }

    final shouldMove = await dialogs.confirmSelectedWindowMove(destinationWorkspace, selectedWindowCount);
    if (!shouldMove) {
      return;
    }

    _mutations.moveSelectedToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
    );
  }

  Future<void> confirmCloseTab(String workspaceId) async {
    final workspaceMatches = _controller.workspaces().where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final shouldClose = await dialogs.confirmTabClose(workspace);
    if (shouldClose) {
      _mutations.toggleOpen(workspaceId);
    }
  }
}

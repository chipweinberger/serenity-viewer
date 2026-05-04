import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_management_dialogs.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_management_mutations.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_navigation.dart';

class WorkspaceShellManagementDependencies {
  const WorkspaceShellManagementDependencies({
    required this.persistenceState,
    required this.workspaceController,
    required this.context,
    required this.mounted,
    required this.workspaces,
    required this.activeWorkspace,
    required this.showMessage,
    required this.navigation,
    required this.mutations,
  });

  final AppEnvironmentState persistenceState;
  final WorkspaceController workspaceController;
  final BuildContext Function() context;
  final bool Function() mounted;
  final List<Workspace> Function() workspaces;
  final Workspace? Function() activeWorkspace;
  final ValueChanged<String> showMessage;
  final WorkspaceShellNavigationApi navigation;
  final WorkspaceShellManagementMutations mutations;
}

class WorkspaceShellManagementApi {
  WorkspaceShellManagementApi(this._dependencies)
    : dialogs = WorkspaceShellManagementDialogs(context: _dependencies.context, mounted: _dependencies.mounted),
      _mutations = _dependencies.mutations;

  final WorkspaceShellManagementDependencies _dependencies;
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
    final workspaceMatches = _dependencies.workspaces().where((entry) => entry.id == workspaceId);
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
    final environment = _dependencies.persistenceState.environment;
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
    final environment = _dependencies.persistenceState.environment;
    final sourceWorkspace = _dependencies.activeWorkspace();
    if (!_dependencies.workspaceController.environment.windowTransfer.canMoveSelectedToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
      hasSelectedWindowIds: _dependencies.workspaceController.expose.hasSelection(),
    )) {
      if (sourceWorkspace != null && destinationWorkspaceId == sourceWorkspace.id) {
        _dependencies.showMessage('Choose a different tab to move those windows.');
      }
      return;
    }

    if (sourceWorkspace == null || environment == null) {
      return;
    }

    if (destinationWorkspaceId == sourceWorkspace.id) {
      _dependencies.showMessage('Choose a different tab to move those windows.');
      return;
    }

    final destinationMatches = environment.workspaces.where((workspace) => workspace.id == destinationWorkspaceId);
    if (destinationMatches.isEmpty) {
      return;
    }

    final destinationWorkspace = destinationMatches.first;
    final selectedWindowCount = _dependencies.workspaceController.expose.countIn(sourceWorkspace);
    if (selectedWindowCount == 0) {
      _dependencies.navigation.clearExposeSelection();
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
    final workspaceMatches = _dependencies.workspaces().where((entry) => entry.id == workspaceId);
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

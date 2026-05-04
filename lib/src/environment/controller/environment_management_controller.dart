import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_dialogs.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_environment_window_transfer_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_expose_controller.dart';

class EnvironmentManagementDependencies {
  const EnvironmentManagementDependencies({
    required this.environmentStoreState,
    required this.windowTransferController,
    required this.exposeController,
    required this.context,
    required this.mounted,
    required this.workspaces,
    required this.activeWorkspace,
    required this.showMessage,
    required this.navigation,
    required this.mutations,
  });

  final EnvironmentStoreState environmentStoreState;
  final WorkspaceEnvironmentWindowTransferController windowTransferController;
  final WorkspaceExposeController exposeController;
  final BuildContext Function() context;
  final bool Function() mounted;
  final List<Workspace> Function() workspaces;
  final Workspace? Function() activeWorkspace;
  final ValueChanged<String> showMessage;
  final EnvironmentNavigationController navigation;
  final EnvironmentManagementMutations mutations;
}

class EnvironmentManagementController {
  EnvironmentManagementController(this._dependencies)
    : dialogs = EnvironmentManagementDialogs(context: _dependencies.context, mounted: _dependencies.mounted),
      _mutations = _dependencies.mutations;

  final EnvironmentManagementDependencies _dependencies;
  final EnvironmentManagementDialogs dialogs;
  final EnvironmentManagementMutations _mutations;

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
    final environment = _dependencies.environmentStoreState.environment;
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
    final environment = _dependencies.environmentStoreState.environment;
    final sourceWorkspace = _dependencies.activeWorkspace();
    if (!_dependencies.windowTransferController.canMoveSelectedToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
      hasSelectedWindowIds: _dependencies.exposeController.hasSelection(),
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
    final selectedWindowCount = _dependencies.exposeController.countIn(sourceWorkspace);
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

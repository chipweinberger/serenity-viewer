import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_scope.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';

class AppShellLibraryContentBuilder {
  const AppShellLibraryContentBuilder({required this.state, required this.actions});

  final AppShellContentState state;
  final AppShellContentActions actions;

  Widget build(MediaLoadPlan workspaceLoadPlan) {
    return LibraryScreen(
      allWorkspaces: state.workspaces,
      openWorkspaces: state.openWorkspaces,
      loadPlan: workspaceLoadPlan,
      searchController: state.searchController,
      workspaceSort: state.uiState.workspaceSort,
      refreshingWorkspaceIds: state.thumbnailController.refreshingWorkspaceIds,
      actions: LibraryScreenActions(
        onSearchChanged: (_) => actions.commitStateChange(() {}),
        onWorkspaceSortChanged: state.chromeController.setWorkspaceSort,
        onToggleWorkspaceOpen: state.workspaceShellController.management.mutations.toggleOpen,
        onRenameWorkspace: state.workspaceShellController.management.renameWorkspace,
        onDeleteWorkspace: state.workspaceShellController.management.confirmDeleteWorkspace,
        onSetActiveWorkspace: state.workspaceShellController.navigation.setActiveWorkspace,
      ),
    );
  }
}

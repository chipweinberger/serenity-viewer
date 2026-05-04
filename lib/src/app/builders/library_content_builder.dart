import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/builders/app_screen_host_scope.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';

class LibraryContentBuilder {
  const LibraryContentBuilder({required this.state, required this.actions});

  final AppScreenHostState state;
  final AppScreenHostActions actions;

  Widget build(MediaLoadPlan workspaceLoadPlan) {
    return LibraryScreen(
      allWorkspaces: state.workspaces,
      openWorkspaces: state.openWorkspaces,
      loadPlan: workspaceLoadPlan,
      searchController: state.searchController,
      workspaceSort: state.uiState.workspaceSort,
      refreshingWorkspaceIds: state.thumbnailController.refreshingWorkspaceIds,
      actions: LibraryScreenActions(
        onSearchChanged: (_) => actions.app.commitStateChange(() {}),
        onWorkspaceSortChanged: state.appUiController.setWorkspaceSort,
        onToggleWorkspaceOpen: state.environmentController.management.toggleOpen,
        onRenameWorkspace: state.environmentController.management.renameWorkspace,
        onDeleteWorkspace: state.environmentController.management.confirmDeleteWorkspace,
        onSetActiveWorkspace: state.environmentController.navigation.setActiveWorkspace,
      ),
    );
  }
}

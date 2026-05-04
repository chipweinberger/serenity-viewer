import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/builders/content_scope.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';

class LibraryContentBuilder {
  const LibraryContentBuilder({required this.state, required this.actions});

  final ContentState state;
  final ContentActions actions;

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
        onWorkspaceSortChanged: state.appUiController.setWorkspaceSort,
        onToggleWorkspaceOpen: state.environmentSession.management.toggleOpen,
        onRenameWorkspace: state.environmentSession.management.renameWorkspace,
        onDeleteWorkspace: state.environmentSession.management.confirmDeleteWorkspace,
        onSetActiveWorkspace: state.environmentSession.navigation.setActiveWorkspace,
      ),
    );
  }
}

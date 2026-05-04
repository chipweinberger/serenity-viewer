import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_main_view_data.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key, required this.state, required this.actions, required this.workspaceLoadPlan});

  final AppMainViewState state;
  final AppMainViewActions actions;
  final MediaLoadPlan workspaceLoadPlan;

  @override
  Widget build(BuildContext context) {
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

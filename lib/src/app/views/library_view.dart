import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({
    super.key,
    required this.model,
    required this.services,
    required this.actions,
    required this.workspaceLoadPlan,
  });

  final AppMainViewModel model;
  final AppMainViewServices services;
  final AppMainViewActions actions;
  final MediaLoadPlan workspaceLoadPlan;

  @override
  Widget build(BuildContext context) {
    return LibraryScreen(
      allWorkspaces: model.workspaces,
      openWorkspaces: model.openWorkspaces,
      loadPlan: workspaceLoadPlan,
      searchController: services.searchController,
      workspaceSort: model.uiState.workspaceSort,
      refreshingWorkspaceIds: services.thumbnailController.refreshingWorkspaceIds,
      actions: LibraryScreenActions(
        onSearchChanged: (_) => actions.app.state.commitStateChange(() {}),
        onWorkspaceSortChanged: services.appUiController.setWorkspaceSort,
        onToggleWorkspaceOpen: services.environmentController.management.toggleOpen,
        onRenameWorkspace: services.environmentController.management.renameWorkspace,
        onDeleteWorkspace: services.environmentController.management.confirmDeleteWorkspace,
        onSetActiveWorkspace: services.environmentController.navigation.setActiveWorkspace,
      ),
    );
  }
}

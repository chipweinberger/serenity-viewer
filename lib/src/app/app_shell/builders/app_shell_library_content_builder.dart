import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';

class AppShellLibraryContentBuilder {
  const AppShellLibraryContentBuilder({
    required this.uiState,
    required this.workspaces,
    required this.openWorkspaces,
    required this.thumbnailController,
    required this.workspaceShellController,
    required this.chromeController,
    required this.searchController,
    required this.commitStateChange,
  });

  final ChromeState uiState;
  final List<Workspace> workspaces;
  final List<Workspace> openWorkspaces;
  final ThumbnailController thumbnailController;
  final WorkspaceShellController workspaceShellController;
  final ChromeController chromeController;
  final TextEditingController searchController;
  final void Function(VoidCallback fn) commitStateChange;

  Widget build(MediaLoadPlan workspaceLoadPlan) {
    return LibraryScreen(
      allWorkspaces: workspaces,
      openWorkspaces: openWorkspaces,
      loadPlan: workspaceLoadPlan,
      searchController: searchController,
      workspaceSort: uiState.workspaceSort,
      refreshingWorkspaceIds: thumbnailController.refreshingWorkspaceIds,
      actions: LibraryScreenActions(
        onSearchChanged: (_) => commitStateChange(() {}),
        onWorkspaceSortChanged: chromeController.setWorkspaceSort,
        onToggleWorkspaceOpen: workspaceShellController.management.toggleWorkspaceOpen,
        onRenameWorkspace: workspaceShellController.management.renameWorkspace,
        onDeleteWorkspace: workspaceShellController.management.confirmDeleteWorkspace,
        onSetActiveWorkspace: workspaceShellController.navigation.setActiveWorkspace,
      ),
    );
  }
}

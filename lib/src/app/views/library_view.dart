import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  ({AppUiState appUiState, EnvironmentStoreState environmentStoreState}) _watchState(BuildContext context) {
    return (appUiState: context.watch<AppUiState>(), environmentStoreState: context.watch<EnvironmentStoreState>());
  }

  ({
    AppUiHandles uiHandles,
    AppUiController appUiController,
    EnvironmentController environmentController,
    ThumbnailController thumbnailController,
  })
  _readDependencies(BuildContext context) {
    return (
      uiHandles: context.read<AppUiHandles>(),
      appUiController: context.read<AppUiController>(),
      environmentController: context.read<EnvironmentController>(),
      thumbnailController: context.read<ThumbnailController>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final dependencies = _readDependencies(context);
    final environment = state.environmentStoreState.environment!;
    final activeWorkspace = deriveActiveWorkspaceOrNull(state.environmentStoreState);

    return LibraryScreen(
      allWorkspaces: deriveWorkspaces(state.environmentStoreState),
      openWorkspaces: deriveOpenWorkspaces(state.environmentStoreState),
      loadPlan: buildWorkspaceLoadPlan(environment: environment, activeWorkspace: activeWorkspace),
      searchController: dependencies.uiHandles.searchController,
      workspaceSort: state.appUiState.workspaceSort,
      refreshingWorkspaceIds: dependencies.thumbnailController.refreshingWorkspaceIds,
      actions: LibraryScreenActions(
        onWorkspaceSortChanged: dependencies.appUiController.setWorkspaceSort,
        onToggleWorkspaceOpen: dependencies.environmentController.management.toggleOpen,
        onRenameWorkspace: dependencies.environmentController.management.renameWorkspace,
        onDeleteWorkspace: dependencies.environmentController.management.confirmDeleteWorkspace,
        onSetActiveWorkspace: dependencies.environmentController.navigation.setActiveWorkspace,
      ),
    );
  }
}

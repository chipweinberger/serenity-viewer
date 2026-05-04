import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  ({EnvironmentStoreState environmentStoreState, WorkspaceSort workspaceSort}) _watchState(BuildContext context) {
    return (
      environmentStoreState: context.watch<EnvironmentStoreState>(),
      workspaceSort: context.select((AppUiState state) => state.workspaceSort),
    );
  }

  ({
    AppUiHandles uiHandles,
    AppUiController appUiController,
    EnvironmentController environmentController,
    WorkspaceController workspaceController,
  })
  _readDependencies(BuildContext context) {
    return (
      uiHandles: context.read<AppUiHandles>(),
      appUiController: context.read<AppUiController>(),
      environmentController: context.read<EnvironmentController>(),
      workspaceController: context.read<WorkspaceController>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final dependencies = _readDependencies(context);
    return LibraryScreen(
      allWorkspaces: deriveWorkspaces(state.environmentStoreState),
      openWorkspaces: deriveOpenWorkspaces(state.environmentStoreState),
      searchController: dependencies.uiHandles.searchController,
      workspaceSort: state.workspaceSort,
      refreshingWorkspaceIds: dependencies.workspaceController.thumbnails.refreshingWorkspaceIds,
      appUiController: dependencies.appUiController,
      environmentController: dependencies.environmentController,
    );
  }
}

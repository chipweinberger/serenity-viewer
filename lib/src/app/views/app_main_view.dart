import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class AppMainView extends StatelessWidget {
  const AppMainView({super.key});

  ({AppUiState appUiState, EnvironmentStoreState environmentStoreState}) _watchState(BuildContext context) {
    return (appUiState: context.watch<AppUiState>(), environmentStoreState: context.watch<EnvironmentStoreState>());
  }

  ({AppUiHandles uiHandles, AppUiController appUiController, EnvironmentController environmentController})
  _readDependencies(BuildContext context) {
    return (
      uiHandles: context.read<AppUiHandles>(),
      appUiController: context.read<AppUiController>(),
      environmentController: context.read<EnvironmentController>(),
    );
  }

  int _activeScreenIndex(AppUiState appUiState) {
    return switch (appUiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildWorkspaceUiOverlay({
    required AppUiState appUiState,
    required EnvironmentStoreState environmentStoreState,
    required AppUiController appUiController,
    required EnvironmentController environmentController,
    required AppUiHandles uiHandles,
  }) {
    final environment = environmentStoreState.environment!;
    return AppHeader(
      windowTitle: deriveWindowTitle(environmentStoreState),
      openWorkspaces: deriveOpenWorkspaces(environmentStoreState),
      activeWorkspaceId: environment.activeWorkspaceId,
      isLibraryScreen: appUiController.isLibraryScreen,
      shouldMoveSelectedWindows: appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: appUiState.draggingTabWorkspaceId,
      tabScrollController: uiHandles.tabScrollController,
      actions: AppTabBarActions(
        onShowWorkspaceOverview: environmentController.navigation.showOverview,
        onSetDraggingTabWorkspaceId: appUiController.setDraggingTabWorkspaceId,
        onReorderOpenWorkspace: environmentController.management.reorderOpen,
        onMoveSelectedExposeWindowsToWorkspace: environmentController.management.moveSelectedExposeWindowsToWorkspace,
        onSetActiveWorkspace: environmentController.navigation.setActiveWorkspace,
        onConfirmCloseTab: environmentController.management.confirmCloseTab,
        onCreateWorkspace: environmentController.management.create,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final dependencies = _readDependencies(context);

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex(state.appUiState),
            children: [const WorkspaceView(), const LibraryView()],
          ),
        ),
        _buildWorkspaceUiOverlay(
          appUiState: state.appUiState,
          environmentStoreState: state.environmentStoreState,
          appUiController: dependencies.appUiController,
          environmentController: dependencies.environmentController,
          uiHandles: dependencies.uiHandles,
        ),
      ],
    );
  }
}

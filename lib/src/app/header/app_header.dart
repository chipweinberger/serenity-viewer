import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/header/app_window_title.dart';
import 'package:serenity_viewer/src/app/header/app_tab_bar.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

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

  Widget _buildPointerShield() {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 84,
      child: AbsorbPointer(absorbing: true, child: ColoredBox(color: Colors.transparent)),
    );
  }

  Widget _buildTabBarFromState({
    required AppUiState appUiState,
    required EnvironmentStoreState environmentStoreState,
    required AppUiHandles uiHandles,
    required AppUiController appUiController,
    required EnvironmentController environmentController,
  }) {
    final environment = environmentStoreState.environment!;
    return Positioned(
      left: 18,
      right: 18,
      top: 28,
      child: AppTabBar(
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
      ),
    );
  }

  Widget _buildTitle(EnvironmentStoreState environmentStoreState) {
    return Positioned(
      top: 10,
      left: 120,
      right: 120,
      child: Center(child: AppWindowTitle(windowTitle: deriveWindowTitle(environmentStoreState))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final dependencies = _readDependencies(context);

    return Stack(
      children: [
        _buildPointerShield(),
        _buildTabBarFromState(
          appUiState: state.appUiState,
          environmentStoreState: state.environmentStoreState,
          uiHandles: dependencies.uiHandles,
          appUiController: dependencies.appUiController,
          environmentController: dependencies.environmentController,
        ),
        _buildTitle(state.environmentStoreState),
      ],
    );
  }
}

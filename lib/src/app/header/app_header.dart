import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/header/app_tab_bar.dart';
import 'package:serenity_viewer/src/app/header/app_window_title.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  ({
    String? currentEnvironmentPath,
    String? draggingTabWorkspaceId,
    String? windowDragTargetWorkspaceId,
    Environment environment,
    bool hasSelectedExposeWindows,
    bool hasUnsavedChanges,
    SerenityScreen screen,
  })
  _watchState(BuildContext context) {
    final environment = context.select((EnvironmentStoreState state) => state.environment);
    if (environment == null) {
      throw StateError('AppHeader requires a loaded environment.');
    }

    return (
      environment: environment,
      currentEnvironmentPath: context.select((EnvironmentStoreState state) => state.currentEnvironmentPath),
      hasUnsavedChanges: context.select((EnvironmentStoreState state) => state.hasUnsavedChanges),
      screen: context.select((AppUiState state) => state.screen),
      draggingTabWorkspaceId: context.select((AppUiState state) => state.draggingTabWorkspaceId),
      windowDragTargetWorkspaceId: context.select((AppUiState state) => state.windowDragTargetWorkspaceId),
      hasSelectedExposeWindows: context.select(
        (WindowInteractionState state) => state.selectedExposeWindowIds.isNotEmpty,
      ),
    );
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
    required Environment environment,
    required String? draggingTabWorkspaceId,
    required String? windowDragTargetWorkspaceId,
    required bool hasSelectedExposeWindows,
    required SerenityScreen screen,
    required AppUiHandles uiHandles,
    required AppUiController appUiController,
    required EnvironmentController environmentController,
  }) {
    return Positioned(
      left: 18,
      right: 18,
      top: 28,
      child: AppTabBar(
        openWorkspaces: environment.workspaces.where((workspace) => workspace.isOpen).toList(),
        activeWorkspaceId: environment.activeWorkspaceId,
        isLibraryScreen: screen == SerenityScreen.library,
        shouldMoveSelectedWindows: screen == SerenityScreen.workspace && hasSelectedExposeWindows,
        draggingTabWorkspaceId: draggingTabWorkspaceId,
        windowDragTargetWorkspaceId: windowDragTargetWorkspaceId,
        tabScrollController: uiHandles.tabScrollController,
        uiHandles: uiHandles,
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

  Widget _buildTitle({required String? currentEnvironmentPath, required bool hasUnsavedChanges}) {
    return Positioned(
      top: 10,
      left: 120,
      right: 120,
      child: Center(
        child: AppWindowTitle(
          windowTitle: currentEnvironmentPath == null || currentEnvironmentPath.isEmpty
              ? 'Serenity${hasUnsavedChanges ? ' *' : ''}'
              : '${currentEnvironmentPath.split(Platform.pathSeparator).last}${hasUnsavedChanges ? ' *' : ''}',
        ),
      ),
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
          environment: state.environment,
          draggingTabWorkspaceId: state.draggingTabWorkspaceId,
          windowDragTargetWorkspaceId: state.windowDragTargetWorkspaceId,
          hasSelectedExposeWindows: state.hasSelectedExposeWindows,
          screen: state.screen,
          uiHandles: dependencies.uiHandles,
          appUiController: dependencies.appUiController,
          environmentController: dependencies.environmentController,
        ),
        _buildTitle(currentEnvironmentPath: state.currentEnvironmentPath, hasUnsavedChanges: state.hasUnsavedChanges),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_main_view_data.dart';
import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

class AppMainView extends StatelessWidget {
  const AppMainView({super.key, required this.state, required this.actions});

  final AppMainViewState state;
  final AppMainViewActions actions;

  int get _activeScreenIndex {
    return switch (state.uiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildWorkspaceScreen(MediaLoadPlan workspaceLoadPlan) {
    return WorkspaceView(state: state, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildLibraryScreen(MediaLoadPlan workspaceLoadPlan) {
    return LibraryView(state: state, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildWorkspaceUiOverlay() {
    return AppHeader(
      windowTitle: state.windowTitle,
      openWorkspaces: state.openWorkspaces,
      activeWorkspaceId: state.environment.activeWorkspaceId,
      isLibraryScreen: state.appUiController.isLibraryScreen,
      shouldMoveSelectedWindows: state.appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: state.uiState.draggingTabWorkspaceId,
      tabScrollController: state.tabScrollController,
      actions: AppTabBarActions(
        onShowWorkspaceOverview: state.environmentController.navigation.showOverview,
        onSetDraggingTabWorkspaceId: state.appUiController.setDraggingTabWorkspaceId,
        onReorderOpenWorkspace: state.environmentController.management.reorderOpen,
        onMoveSelectedExposeWindowsToWorkspace:
            state.environmentController.management.moveSelectedExposeWindowsToWorkspace,
        onSetActiveWorkspace: state.environmentController.navigation.setActiveWorkspace,
        onConfirmCloseTab: state.environmentController.management.confirmCloseTab,
        onCreateWorkspace: state.environmentController.management.create,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspaceLoadPlan = buildWorkspaceLoadPlan(
      environment: state.environment,
      activeWorkspace: state.activeWorkspaceOrNull,
    );
    state.sharedVideoControllerPool.syncSharedVideoControllers(
      loadPlan: workspaceLoadPlan,
      environment: state.environment,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex,
            children: [_buildWorkspaceScreen(workspaceLoadPlan), _buildLibraryScreen(workspaceLoadPlan)],
          ),
        ),
        _buildWorkspaceUiOverlay(),
      ],
    );
  }
}

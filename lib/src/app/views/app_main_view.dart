import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/views/app_main_view_binding_builder.dart';
import 'package:serenity_viewer/src/app/views/app_main_view_contract.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

export 'package:serenity_viewer/src/app/views/app_main_view_binding_builder.dart';
export 'package:serenity_viewer/src/app/views/app_main_view_contract.dart';

class AppMainView extends StatelessWidget {
  const AppMainView({super.key});

  int _activeScreenIndex(AppMainViewModel model) {
    return switch (model.uiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildWorkspaceScreen(
    MediaLoadPlan workspaceLoadPlan, {
    required AppMainViewModel model,
    required AppMainViewServices services,
    required AppMainViewActions actions,
  }) {
    return WorkspaceView(model: model, services: services, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildLibraryScreen(
    MediaLoadPlan workspaceLoadPlan, {
    required AppMainViewModel model,
    required AppMainViewServices services,
    required AppMainViewActions actions,
  }) {
    return LibraryView(model: model, services: services, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildWorkspaceUiOverlay({
    required AppMainViewModel model,
    required AppMainViewServices services,
  }) {
    return AppHeader(
      windowTitle: model.windowTitle,
      openWorkspaces: model.openWorkspaces,
      activeWorkspaceId: model.environment.activeWorkspaceId,
      isLibraryScreen: services.appUiController.isLibraryScreen,
      shouldMoveSelectedWindows: services.appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: model.uiState.draggingTabWorkspaceId,
      tabScrollController: services.tabScrollController,
      actions: AppTabBarActions(
        onShowWorkspaceOverview: services.environmentController.navigation.showOverview,
        onSetDraggingTabWorkspaceId: services.appUiController.setDraggingTabWorkspaceId,
        onReorderOpenWorkspace: services.environmentController.management.reorderOpen,
        onMoveSelectedExposeWindowsToWorkspace:
            services.environmentController.management.moveSelectedExposeWindowsToWorkspace,
        onSetActiveWorkspace: services.environmentController.navigation.setActiveWorkspace,
        onConfirmCloseTab: services.environmentController.management.confirmCloseTab,
        onCreateWorkspace: services.environmentController.management.create,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bindings = buildAppMainViewBindings(context);
    final model = bindings.model;
    final services = bindings.services;
    final actions = bindings.actions;
    final workspaceLoadPlan = buildWorkspaceLoadPlan(
      environment: model.environment,
      activeWorkspace: model.activeWorkspaceOrNull,
    );
    services.sharedVideoControllerPool.syncSharedVideoControllers(
      loadPlan: workspaceLoadPlan,
      environment: model.environment,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex(model),
            children: [
              _buildWorkspaceScreen(workspaceLoadPlan, model: model, services: services, actions: actions),
              _buildLibraryScreen(workspaceLoadPlan, model: model, services: services, actions: actions),
            ],
          ),
        ),
        _buildWorkspaceUiOverlay(model: model, services: services),
      ],
    );
  }
}

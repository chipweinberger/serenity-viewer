import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/builders/app_top_bar_overlay_builder.dart';
import 'package:serenity_viewer/src/app/builders/app_screen_host_scope.dart';
import 'package:serenity_viewer/src/app/builders/library_content_builder.dart';
import 'package:serenity_viewer/src/app/builders/workspace_content_builder.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

class AppScreenHostBuilder {
  const AppScreenHostBuilder({required this.state, required this.actions});

  final AppScreenHostState state;
  final AppScreenHostActions actions;

  Widget build() {
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

  int get _activeScreenIndex {
    return switch (state.uiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildWorkspaceScreen(MediaLoadPlan workspaceLoadPlan) {
    return WorkspaceContentBuilder(state: state, actions: actions).build(workspaceLoadPlan);
  }

  Widget _buildLibraryScreen(MediaLoadPlan workspaceLoadPlan) {
    return LibraryContentBuilder(state: state, actions: actions).build(workspaceLoadPlan);
  }

  Widget _buildWorkspaceUiOverlay() {
    return AppTopBarOverlayBuilder(state: state).build();
  }
}

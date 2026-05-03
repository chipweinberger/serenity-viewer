import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_chrome_overlay_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_scope.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_library_content_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_workspace_content_builder.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';
import 'package:serenity_viewer/src/workspace_loading/workspace_load_plan.dart';

class AppShellContentBuilder {
  const AppShellContentBuilder({required this.state, required this.actions});

  final AppShellContentState state;
  final AppShellContentActions actions;

  Widget build() {
    final workspaceLoadPlan = buildWorkspaceLoadPlan(
      environment: state.environment,
      activeWorkspace: state.activeWorkspaceOrNull,
    );
    state.mediaBridge.syncSharedVideoControllers(loadPlan: workspaceLoadPlan, environment: state.environment);

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex,
            children: [_buildWorkspaceScreen(workspaceLoadPlan), _buildLibraryScreen(workspaceLoadPlan)],
          ),
        ),
        _buildWorkspaceChromeOverlay(),
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
    return AppShellWorkspaceContentBuilder(state: state, actions: actions).build(workspaceLoadPlan);
  }

  Widget _buildLibraryScreen(MediaLoadPlan workspaceLoadPlan) {
    return AppShellLibraryContentBuilder(state: state, actions: actions).build(workspaceLoadPlan);
  }

  Widget _buildWorkspaceChromeOverlay() {
    return AppShellChromeOverlayBuilder(state: state).build();
  }
}

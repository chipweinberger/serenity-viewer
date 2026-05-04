import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/session/environment_session_types.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

class EnvironmentViewDependencies {
  const EnvironmentViewDependencies({
    required this.environmentStoreState,
    required this.appUiState,
    required this.workspaceController,
    required this.openWorkspaces,
    required this.updateEnvironment,
    required this.showWorkspaceScreen,
    required this.showLibraryScreen,
    required this.workspaceSwitchTarget,
    required this.refreshActiveWorkspaceThumbnail,
  });

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WorkspaceController workspaceController;
  final List<Workspace> Function() openWorkspaces;
  final ValueChanged<Environment> updateEnvironment;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final SerenityShowLibraryScreen showLibraryScreen;
  final SerenityWorkspaceSwitchTargetResolver workspaceSwitchTarget;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
}

class EnvironmentViewController {
  EnvironmentViewController(this._dependencies);

  final EnvironmentViewDependencies _dependencies;

  void toggleSelectedWindow(String windowId) {
    _dependencies.workspaceController.expose.toggle(windowId);
  }

  void clearExposeSelection() {
    _dependencies.workspaceController.expose.clear();
  }

  void toggleOverview() {
    if (_dependencies.appUiState.screen == SerenityScreen.workspace) {
      unawaited(_dependencies.refreshActiveWorkspaceThumbnail());
    }

    if (_dependencies.appUiState.screen == SerenityScreen.library) {
      _dependencies.showWorkspaceScreen();
    } else {
      _dependencies.showLibraryScreen();
    }
  }

  void showOverview() {
    if (_dependencies.appUiState.screen == SerenityScreen.workspace) {
      unawaited(_dependencies.refreshActiveWorkspaceThumbnail());
    }

    _dependencies.showLibraryScreen();
  }

  void switchWorkspace(int direction) {
    final environment = _dependencies.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    final target = _dependencies.workspaceSwitchTarget(
      openWorkspaces: _dependencies.openWorkspaces(),
      activeWorkspaceId: environment.activeWorkspaceId,
      direction: direction,
    );
    if (target.showsLibrary) {
      showOverview();
      return;
    }

    unawaited(setActiveWorkspace(target.workspaceId!));
  }

  Future<void> setActiveWorkspace(String workspaceId) async {
    final environment = _dependencies.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    final currentWorkspaceId = environment.activeWorkspaceId;
    if (currentWorkspaceId != workspaceId) {
      unawaited(_dependencies.refreshActiveWorkspaceThumbnail());
    }

    final shouldPreserveExpose =
        _dependencies.appUiState.screen == SerenityScreen.workspace &&
        _dependencies.appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
    _dependencies.updateEnvironment(
      environment.copyWith(
        activeWorkspaceId: workspaceId,
        workspaces: environment.workspaces
            .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: true) : workspace)
            .toList(),
      ),
    );

    _dependencies.showWorkspaceScreen(
      workspaceLayoutMode: shouldPreserveExpose ? WorkspaceLayoutMode.expose : WorkspaceLayoutMode.freeform,
    );
  }
}

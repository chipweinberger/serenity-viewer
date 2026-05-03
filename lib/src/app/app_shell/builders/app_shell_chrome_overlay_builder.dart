import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_overlay.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';

class AppShellChromeOverlayBuilder {
  const AppShellChromeOverlayBuilder({
    required this.windowTitle,
    required this.environment,
    required this.openWorkspaces,
    required this.uiState,
    required this.chromeController,
    required this.workspaceShellController,
    required this.tabScrollController,
  });

  final String windowTitle;
  final Environment environment;
  final List<Workspace> openWorkspaces;
  final ChromeState uiState;
  final ChromeController chromeController;
  final WorkspaceShellController workspaceShellController;
  final ScrollController tabScrollController;

  Widget build() {
    return WorkspaceChromeOverlay(
      windowTitle: windowTitle,
      openWorkspaces: openWorkspaces,
      activeWorkspaceId: environment.activeWorkspaceId,
      isLibraryScreen: chromeController.isLibraryScreen,
      shouldMoveSelectedWindows: chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: uiState.draggingTabWorkspaceId,
      tabScrollController: tabScrollController,
      actions: WorkspaceChromeOverlayActions(
        onShowWorkspaceOverview: workspaceShellController.navigation.showOverview,
        onSetDraggingTabWorkspaceId: chromeController.setDraggingTabWorkspaceId,
        onReorderOpenWorkspace: workspaceShellController.management.reorderOpenWorkspace,
        onMoveSelectedExposeWindowsToWorkspace:
            workspaceShellController.management.moveSelectedExposeWindowsToWorkspace,
        onSetActiveWorkspace: workspaceShellController.navigation.setActiveWorkspace,
        onConfirmCloseTab: workspaceShellController.management.confirmCloseTab,
        onCreateWorkspace: workspaceShellController.management.createWorkspace,
      ),
    );
  }
}

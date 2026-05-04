import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_scope.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_overlay.dart';

class AppShellChromeOverlayBuilder {
  const AppShellChromeOverlayBuilder({required this.state});

  final AppShellContentState state;

  Widget build() {
    return WorkspaceChromeOverlay(
      windowTitle: state.windowTitle,
      openWorkspaces: state.openWorkspaces,
      activeWorkspaceId: state.environment.activeWorkspaceId,
      isLibraryScreen: state.chromeController.isLibraryScreen,
      shouldMoveSelectedWindows: state.chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: state.uiState.draggingTabWorkspaceId,
      tabScrollController: state.tabScrollController,
      actions: WorkspaceChromeOverlayActions(
        onShowWorkspaceOverview: state.workspaceShellController.navigation.showOverview,
        onSetDraggingTabWorkspaceId: state.chromeController.setDraggingTabWorkspaceId,
        onReorderOpenWorkspace: state.workspaceShellController.management.mutations.reorderOpen,
        onMoveSelectedExposeWindowsToWorkspace:
            state.workspaceShellController.management.moveSelectedExposeWindowsToWorkspace,
        onSetActiveWorkspace: state.workspaceShellController.navigation.setActiveWorkspace,
        onConfirmCloseTab: state.workspaceShellController.management.confirmCloseTab,
        onCreateWorkspace: state.workspaceShellController.management.mutations.create,
      ),
    );
  }
}

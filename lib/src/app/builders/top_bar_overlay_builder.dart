import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/builders/content_scope.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_top_bar_overlay.dart';

class TopBarOverlayBuilder {
  const TopBarOverlayBuilder({required this.state});

  final ContentState state;

  Widget build() {
    return WorkspaceTopBarOverlay(
      windowTitle: state.windowTitle,
      openWorkspaces: state.openWorkspaces,
      activeWorkspaceId: state.environment.activeWorkspaceId,
      isLibraryScreen: state.appUiController.isLibraryScreen,
      shouldMoveSelectedWindows: state.appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: state.uiState.draggingTabWorkspaceId,
      tabScrollController: state.tabScrollController,
      actions: WorkspaceTopBarOverlayActions(
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
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

class AppUiController {
  AppUiController({
    required this.appUiState,
    required this.windowInteractionState,
    required this.refreshWorkspaceTracking,
  });

  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final VoidCallback refreshWorkspaceTracking;

  bool get isWorkspaceScreen => appUiState.screen == SerenityScreen.workspace;
  bool get isLibraryScreen => appUiState.screen == SerenityScreen.library;
  bool get isExposeMode => isWorkspaceScreen && appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
  bool get hasSelectedExposeWindows => windowInteractionState.selectedExposeWindowIds.isNotEmpty;

  bool isWorkspaceTabSelected({required String workspaceId, required String activeWorkspaceId}) {
    return !isLibraryScreen && workspaceId == activeWorkspaceId;
  }

  bool isWorkspaceTabDragging(String workspaceId) {
    return appUiState.draggingTabWorkspaceId == workspaceId;
  }

  bool isWorkspaceWindowDropTarget(String workspaceId) {
    return appUiState.windowDragTargetWorkspaceId == workspaceId;
  }

  bool get shouldMoveSelectedWindowsToWorkspaceOnTap {
    return isWorkspaceScreen && hasSelectedExposeWindows;
  }

  void applyUiState({
    SerenityScreen? screen,
    WorkspaceLayoutMode? workspaceLayoutMode,
    bool resetEditMode = false,
    bool clearExposeSelection = false,
    bool refreshWorkspaceTrackingEnabled = true,
  }) {
    _applyUiState(
      screen: screen,
      workspaceLayoutMode: workspaceLayoutMode,
      resetEditMode: resetEditMode,
      clearExposeSelection: clearExposeSelection,
      refreshWorkspaceTrackingEnabled: refreshWorkspaceTrackingEnabled,
    );
  }

  void showWorkspaceScreen({
    WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
    bool resetEditMode = true,
    bool clearExposeSelection = true,
    bool refreshWorkspaceTrackingEnabled = true,
  }) {
    _applyUiState(
      screen: SerenityScreen.workspace,
      workspaceLayoutMode: workspaceLayoutMode,
      resetEditMode: resetEditMode,
      clearExposeSelection: clearExposeSelection,
      refreshWorkspaceTrackingEnabled: refreshWorkspaceTrackingEnabled,
    );
  }

  void showLibraryScreen({
    bool resetEditMode = true,
    bool clearExposeSelection = true,
    bool refreshWorkspaceTrackingEnabled = true,
  }) {
    _applyUiState(
      screen: SerenityScreen.library,
      workspaceLayoutMode: WorkspaceLayoutMode.freeform,
      resetEditMode: resetEditMode,
      clearExposeSelection: clearExposeSelection,
      refreshWorkspaceTrackingEnabled: refreshWorkspaceTrackingEnabled,
    );
  }

  void toggleExpose() {
    final nextWorkspaceLayoutMode = appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose
        ? WorkspaceLayoutMode.freeform
        : WorkspaceLayoutMode.expose;
    showWorkspaceScreen(
      workspaceLayoutMode: nextWorkspaceLayoutMode,
      resetEditMode: nextWorkspaceLayoutMode != WorkspaceLayoutMode.expose,
      clearExposeSelection: nextWorkspaceLayoutMode != WorkspaceLayoutMode.expose,
    );
  }

  void setDraggingTabWorkspaceId(String? workspaceId) {
    appUiState.setDraggingTabWorkspaceId(workspaceId);
  }

  void setWindowDragTargetWorkspaceId(String? workspaceId) {
    appUiState.setWindowDragTargetWorkspaceId(workspaceId);
  }

  void beginWindowDrag(String sourceWorkspaceId) {
    appUiState.setDraggingWindowSourceWorkspaceId(sourceWorkspaceId);
  }

  void endWindowDrag() {
    appUiState.setDraggingWindowSourceWorkspaceId(null);
    appUiState.setWindowDragTargetWorkspaceId(null);
  }

  void setWorkspaceSort(WorkspaceSort sort) {
    appUiState.setWorkspaceSort(sort);
  }

  WorkspaceSwitchTarget workspaceSwitchTarget({
    required List<Workspace> openWorkspaces,
    required String activeWorkspaceId,
    required int direction,
  }) {
    final tabCount = openWorkspaces.length + 1;
    if (tabCount == 0) {
      return const WorkspaceSwitchTarget.showLibrary();
    }

    final currentIndex = isLibraryScreen
        ? 0
        : openWorkspaces.indexWhere((workspace) => workspace.id == activeWorkspaceId) + 1;
    final nextIndex = (currentIndex + direction) % tabCount;
    final safeIndex = nextIndex < 0 ? tabCount - 1 : nextIndex;

    if (safeIndex == 0) {
      return const WorkspaceSwitchTarget.showLibrary();
    }

    return WorkspaceSwitchTarget.showWorkspace(openWorkspaces[safeIndex - 1].id);
  }

  void _applyUiState({
    SerenityScreen? screen,
    WorkspaceLayoutMode? workspaceLayoutMode,
    bool resetEditMode = false,
    bool clearExposeSelection = false,
    bool refreshWorkspaceTrackingEnabled = true,
  }) {
    final nextScreen = screen ?? appUiState.screen;
    final nextWorkspaceLayoutMode = workspaceLayoutMode ?? appUiState.workspaceLayoutMode;
    final nextEditMode = resetEditMode ? false : appUiState.editMode;
    final shouldClearSelection = clearExposeSelection && windowInteractionState.selectedExposeWindowIds.isNotEmpty;
    final stateChanged = appUiState.update(
      screen: nextScreen,
      workspaceLayoutMode: nextWorkspaceLayoutMode,
      editMode: nextEditMode,
    );

    if (shouldClearSelection) {
      windowInteractionState.clearSelectedExposeWindows();
    }

    if (refreshWorkspaceTrackingEnabled && (stateChanged || shouldClearSelection)) {
      refreshWorkspaceTracking();
    }
  }
}

class WorkspaceSwitchTarget {
  const WorkspaceSwitchTarget.showLibrary() : workspaceId = null;
  const WorkspaceSwitchTarget.showWorkspace(this.workspaceId);

  final String? workspaceId;

  bool get showsLibrary => workspaceId == null;
}

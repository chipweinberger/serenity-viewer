import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

class AppUiController {
  AppUiController({
    required this.appUiState,
    required this.windowInteractionState,
    required this.commitStateChange,
    required this.refreshWorkspaceTracking,
  });

  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final StateSetter commitStateChange;
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
    if (appUiState.draggingTabWorkspaceId == workspaceId) {
      return;
    }

    commitStateChange(() {
      appUiState.draggingTabWorkspaceId = workspaceId;
    });
  }

  void setWorkspaceSort(WorkspaceSort sort) {
    if (appUiState.workspaceSort == sort) {
      return;
    }

    commitStateChange(() {
      appUiState.workspaceSort = sort;
    });
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
    final changed =
        nextScreen != appUiState.screen ||
        nextWorkspaceLayoutMode != appUiState.workspaceLayoutMode ||
        nextEditMode != appUiState.editMode ||
        shouldClearSelection;

    if (changed) {
      commitStateChange(() {
        appUiState.screen = nextScreen;
        appUiState.workspaceLayoutMode = nextWorkspaceLayoutMode;
        if (resetEditMode) {
          appUiState.editMode = false;
        }
        if (clearExposeSelection) {
          windowInteractionState.selectedExposeWindowIds.clear();
        }
      });
    }

    if (refreshWorkspaceTrackingEnabled) {
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

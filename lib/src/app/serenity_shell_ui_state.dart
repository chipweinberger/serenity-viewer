// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellUiState on _SerenityShellState {
  void _applyUiState({
    SerenityScreen? screen,
    WorkspaceLayoutMode? workspaceLayoutMode,
    bool resetEditMode = false,
    bool clearExposeSelection = false,
    bool refreshWorkspaceTracking = true,
  }) {
    final nextScreen = screen ?? _uiState.screen;
    final nextWorkspaceLayoutMode = workspaceLayoutMode ?? _uiState.workspaceLayoutMode;
    final nextEditMode = resetEditMode ? false : _uiState.editMode;
    final shouldClearSelection = clearExposeSelection && _windowInteractionState.selectedExposeWindowIds.isNotEmpty;
    final changed =
        nextScreen != _uiState.screen ||
        nextWorkspaceLayoutMode != _uiState.workspaceLayoutMode ||
        nextEditMode != _uiState.editMode ||
        shouldClearSelection;
    if (changed) {
      setState(() {
        _uiState.screen = nextScreen;
        _uiState.workspaceLayoutMode = nextWorkspaceLayoutMode;
        if (resetEditMode) {
          _uiState.editMode = false;
        }
        if (clearExposeSelection) {
          _windowInteractionState.selectedExposeWindowIds.clear();
        }
      });
    }
    if (refreshWorkspaceTracking) {
      _refreshWorkspaceViewTracking();
    }
  }

  void _showWorkspaceScreen({
    WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
    bool resetEditMode = true,
    bool clearExposeSelection = true,
    bool refreshWorkspaceTracking = true,
  }) {
    _applyUiState(
      screen: SerenityScreen.workspace,
      workspaceLayoutMode: workspaceLayoutMode,
      resetEditMode: resetEditMode,
      clearExposeSelection: clearExposeSelection,
      refreshWorkspaceTracking: refreshWorkspaceTracking,
    );
  }

  void _showLibraryScreen({
    bool resetEditMode = true,
    bool clearExposeSelection = true,
    bool refreshWorkspaceTracking = true,
  }) {
    _applyUiState(
      screen: SerenityScreen.library,
      workspaceLayoutMode: WorkspaceLayoutMode.freeform,
      resetEditMode: resetEditMode,
      clearExposeSelection: clearExposeSelection,
      refreshWorkspaceTracking: refreshWorkspaceTracking,
    );
  }
}

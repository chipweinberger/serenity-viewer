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
    final nextScreen = screen ?? _screen;
    final nextWorkspaceLayoutMode = workspaceLayoutMode ?? _workspaceLayoutMode;
    final nextEditMode = resetEditMode ? false : _editMode;
    final shouldClearSelection = clearExposeSelection && _windowInteractionState.selectedExposeWindowIds.isNotEmpty;
    final changed =
        nextScreen != _screen ||
        nextWorkspaceLayoutMode != _workspaceLayoutMode ||
        nextEditMode != _editMode ||
        shouldClearSelection;
    if (changed) {
      setState(() {
        _screen = nextScreen;
        _workspaceLayoutMode = nextWorkspaceLayoutMode;
        if (resetEditMode) {
          _editMode = false;
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

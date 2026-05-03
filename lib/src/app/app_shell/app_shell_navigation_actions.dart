// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/app_shell/app_shell.dart';

extension _AppShellNavigationActions on _AppShellState {
  void _showWorkspaceScreen({
    WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
    bool resetEditMode = true,
    bool clearExposeSelection = true,
    bool refreshWorkspaceTracking = true,
  }) {
    _chromeController.showWorkspaceScreen(
      workspaceLayoutMode: workspaceLayoutMode,
      resetEditMode: resetEditMode,
      clearExposeSelection: clearExposeSelection,
      refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
    );
  }

  void _showLibraryScreen({
    bool resetEditMode = true,
    bool clearExposeSelection = true,
    bool refreshWorkspaceTracking = true,
  }) {
    _chromeController.showLibraryScreen(
      resetEditMode: resetEditMode,
      clearExposeSelection: clearExposeSelection,
      refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
    );
  }
}

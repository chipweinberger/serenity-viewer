// ignore_for_file: invalid_use_of_protected_member

part of 'app_shell.dart';

extension _AppShellWindowHistoryActions on _AppShellState {
  WorkspaceWindowState? _focusedWindowOrNull() {
    return _workspaceController.focusedWindowOrNull(_activeWorkspaceOrNull);
  }

  void _closeWindow(String workspaceId, String windowId) {
    final workspace = _workspaces.firstWhere((entry) => entry.id == workspaceId);
    final windowMatches = workspace.windows.where((entry) => entry.asset.id == windowId);
    final window = windowMatches.isEmpty ? null : windowMatches.first;
    if (window == null) {
      return;
    }

    setState(() {
      _workspaceController.rememberClosedWindow(
        _recentlyClosedWindows,
        maxRecentlyClosedWindows: _AppShellState._maxRecentlyClosedWindows,
        workspace: workspace,
        window: window,
      );
      _workspaceController.clearWindowRuntimeState(windowId);
    });

    _replaceWorkspace(
      workspace.copyWith(windows: workspace.windows.where((entry) => entry.asset.id != windowId).toList()),
    );
  }

  void _removeWindow(String workspaceId, String windowId) {
    _workspaceController.removeWindowSelection(windowId);
    _closeWindow(workspaceId, windowId);
  }

  void _restoreRecentlyClosedWindow([RecentlyClosedWindowEntry? entry]) {
    final targetEntry = entry ?? (_recentlyClosedWindows.isEmpty ? null : _recentlyClosedWindows.first);
    final environment = _persistenceState.environment;
    if (targetEntry == null || environment == null) {
      _showMessage('There are no recently closed windows to restore.');
      return;
    }

    final workspaceMatches = _workspaces.where((entry) => entry.id == targetEntry.workspaceId);
    final workspace = workspaceMatches.isEmpty ? null : workspaceMatches.first;
    if (workspace == null) {
      setState(() {
        _recentlyClosedWindows.remove(targetEntry);
      });
      _showMessage('The original workspace for that window is no longer available.');
      return;
    }

    final nextZ = workspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    final restoredWindow = targetEntry.window.copyWith(zIndex: nextZ + 1);

    setState(() {
      _recentlyClosedWindows.remove(targetEntry);
    });

    _updateEnvironment(
      environment.copyWith(
        activeWorkspaceId: workspace.id,
        workspaces: environment.workspaces
            .map(
              (entry) => entry.id == workspace.id
                  ? entry.copyWith(windows: [...workspace.windows, restoredWindow], isOpen: true)
                  : entry,
            )
            .toList(),
      ),
    );

    if (_uiState.screen == SerenityScreen.library) {
      _showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false, refreshWorkspaceTracking: false);
    }
  }
}

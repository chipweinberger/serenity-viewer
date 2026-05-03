// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityWindowHistoryActions on _SerenityShellState {
  AssetWindowState? _focusedWindowOrNull() {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null || workspace.windows.isEmpty) {
      return null;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sortedWindows.last;
  }

  void _rememberClosedWindow(WorkspaceState workspace, AssetWindowState window) {
    _recentlyClosedWindows.insert(
      0,
      RecentlyClosedWindowEntry(
        workspaceId: workspace.id,
        workspaceName: workspace.name,
        window: window,
        closedAt: DateTime.now(),
      ),
    );

    if (_recentlyClosedWindows.length > _SerenityShellState._maxRecentlyClosedWindows) {
      _recentlyClosedWindows.removeRange(_SerenityShellState._maxRecentlyClosedWindows, _recentlyClosedWindows.length);
    }
  }

  void _closeWindow(String workspaceId, String windowId) {
    final workspace = _workspaces.firstWhere((entry) => entry.id == workspaceId);
    final windowMatches = workspace.windows.where((entry) => entry.asset.id == windowId);
    final window = windowMatches.isEmpty ? null : windowMatches.first;
    if (window == null) {
      return;
    }

    setState(() {
      _rememberClosedWindow(workspace, window);
      _previousWindowZOrders.remove(windowId);
      _pausedVideoWindows.remove(windowId);
    });

    _replaceWorkspace(
      workspace.copyWith(windows: workspace.windows.where((entry) => entry.asset.id != windowId).toList()),
    );
  }

  void _removeWindow(String workspaceId, String windowId) {
    _selectedExposeWindowIds.remove(windowId);
    _closeWindow(workspaceId, windowId);
  }

  void _restoreRecentlyClosedWindow([RecentlyClosedWindowEntry? entry]) {
    final targetEntry = entry ?? (_recentlyClosedWindows.isEmpty ? null : _recentlyClosedWindows.first);
    final session = _session;
    if (targetEntry == null || session == null) {
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

    _updateSession(
      session.copyWith(
        activeWorkspaceId: workspace.id,
        workspaces: session.workspaces
            .map(
              (entry) => entry.id == workspace.id
                  ? entry.copyWith(windows: [...workspace.windows, restoredWindow], isOpen: true)
                  : entry,
            )
            .toList(),
      ),
    );

    if (_screen == SerenityScreen.library) {
      _showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false, refreshWorkspaceTracking: false);
    }
  }
}

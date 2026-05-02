// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellSessionActions on _SerenityShellState {
  void _updateSession(SerenitySessionState nextSession) {
    setState(() {
      _session = nextSession;
    });
    _refreshWorkspaceViewTracking();
    unawaited(_syncWindowTitle());
    _queueSave();
  }

  void _replaceWorkspace(WorkspaceState nextWorkspace, {bool queueThumbnail = true}) {
    final session = _session!;
    _updateSession(
      session.copyWith(
        workspaces: session.workspaces
            .map((workspace) => workspace.id == nextWorkspace.id ? nextWorkspace : workspace)
            .toList(),
      ),
    );
    if (queueThumbnail) {
      _thumbnailDirtyWorkspaces.add(nextWorkspace.id);
    }
  }

  void _toggleExpose() {
    setState(() {
      _screen = SerenityScreen.workspace;
      _workspaceLayoutMode = _workspaceLayoutMode == WorkspaceLayoutMode.expose
          ? WorkspaceLayoutMode.freeform
          : WorkspaceLayoutMode.expose;
      if (_workspaceLayoutMode != WorkspaceLayoutMode.expose) {
        _editMode = false;
        _selectedExposeWindowIds.clear();
      }
    });
    _refreshWorkspaceViewTracking();
  }

  Future<void> _toggleWorkspaceOverview() async {
    if (_screen == SerenityScreen.workspace) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    setState(() {
      final showingLibrary = _screen == SerenityScreen.library;
      _screen = showingLibrary ? SerenityScreen.workspace : SerenityScreen.library;
      _workspaceLayoutMode = WorkspaceLayoutMode.freeform;
      _editMode = false;
      _selectedExposeWindowIds.clear();
    });
    _refreshWorkspaceViewTracking();
  }

  Future<void> _showWorkspaceOverview() async {
    if (_screen == SerenityScreen.workspace) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    setState(() {
      _screen = SerenityScreen.library;
      _workspaceLayoutMode = WorkspaceLayoutMode.freeform;
      _editMode = false;
      _selectedExposeWindowIds.clear();
    });
    _refreshWorkspaceViewTracking();
  }

  Future<void> _switchWorkspace(int direction) async {
    final pinnedWorkspaces = _pinnedWorkspaces;
    final tabCount = pinnedWorkspaces.length + 1;
    if (tabCount == 0) {
      return;
    }

    final currentIndex = _screen == SerenityScreen.library
        ? 0
        : pinnedWorkspaces.indexWhere((workspace) => workspace.id == _session!.activeWorkspaceId) + 1;
    final nextIndex = (currentIndex + direction) % tabCount;
    final safeIndex = nextIndex < 0 ? tabCount - 1 : nextIndex;

    if (safeIndex == 0) {
      unawaited(_showWorkspaceOverview());
      return;
    }

    final nextWorkspace = pinnedWorkspaces[safeIndex - 1];
    unawaited(_setActiveWorkspace(nextWorkspace.id));
  }

  Future<void> _setActiveWorkspace(String workspaceId) async {
    final session = _session!;
    final currentWorkspaceId = session.activeWorkspaceId;
    if (currentWorkspaceId != workspaceId) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    final shouldPreserveExpose =
        _screen == SerenityScreen.workspace && _workspaceLayoutMode == WorkspaceLayoutMode.expose;
    _updateSession(
      session.copyWith(
        activeWorkspaceId: workspaceId,
        workspaces: session.workspaces
            .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: true) : workspace)
            .toList(),
      ),
    );

    setState(() {
      _screen = SerenityScreen.workspace;
      _workspaceLayoutMode = shouldPreserveExpose ? WorkspaceLayoutMode.expose : WorkspaceLayoutMode.freeform;
      _editMode = false;
      _selectedExposeWindowIds.clear();
    });
    _refreshWorkspaceViewTracking();
  }

  void _toggleExposeWindowSelected(String windowId) {
    setState(() {
      if (_selectedExposeWindowIds.contains(windowId)) {
        _selectedExposeWindowIds.remove(windowId);
      } else {
        _selectedExposeWindowIds.add(windowId);
      }
    });
  }

  void _clearExposeSelection() {
    if (_selectedExposeWindowIds.isEmpty) {
      return;
    }
    setState(() {
      _selectedExposeWindowIds.clear();
    });
  }
}

// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellSessionActions on _SerenityShellState {
  static const double _appliedExposeViewportZoomFactor = 0.0625;

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
    _updateSession(SerenityWorkspaceMutations.replaceWorkspace(session, nextWorkspace));
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

  void _setPinnedHoverWindow(String? windowId) {
    if (_pinnedHoverWindowId == windowId) {
      return;
    }
    setState(() {
      _pinnedHoverWindowId = windowId;
    });
  }

  void _clearPinnedHoverWindow() {
    _setPinnedHoverWindow(null);
  }

  void _flashWindow(String windowId) {
    _windowFlashTimer?.cancel();
    setState(() {
      _flashedWindowId = windowId;
      _windowFlashNonce += 1;
    });
    _windowFlashTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || _flashedWindowId != windowId) {
        return;
      }
      setState(() {
        _flashedWindowId = null;
      });
    });
  }

  void _applyExposeGridToWorkspace() {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null ||
        _screen != SerenityScreen.workspace ||
        _workspaceLayoutMode != WorkspaceLayoutMode.expose) {
      return;
    }
    if (_workspaceViewportSize.width <= 0 || _workspaceViewportSize.height <= 0 || workspace.windows.isEmpty) {
      return;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
    final exposeLayouts = computeExposeLayoutRects(windows: sortedWindows, viewportSize: _workspaceViewportSize);
    if (exposeLayouts.isEmpty) {
      return;
    }

    final viewportCenter = _workspaceViewportSize.center(Offset.zero);
    final safeViewportZoom = workspace.viewportZoom <= 0 ? 1.0 : workspace.viewportZoom;
    final nextViewportZoom = _clampWorkspaceZoom(safeViewportZoom * _appliedExposeViewportZoomFactor);
    final relaidOutById = <String, AssetWindowState>{};
    for (final layout in exposeLayouts) {
      final rect = layout.rect;
      final nextSize = Size(rect.width / nextViewportZoom, rect.height / nextViewportZoom);
      final nextPosition = _clampWindowPosition(
        Offset(
          workspace.viewportCenter.dx + ((rect.left - viewportCenter.dx) / nextViewportZoom),
          workspace.viewportCenter.dy + ((rect.top - viewportCenter.dy) / nextViewportZoom),
        ),
        nextSize,
      );
      relaidOutById[layout.window.asset.id] = layout.window.copyWith(position: nextPosition, size: nextSize);
    }

    _replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) => relaidOutById[window.asset.id] ?? window).toList(),
        viewportZoom: nextViewportZoom,
      ),
    );

    setState(() {
      _workspaceLayoutMode = WorkspaceLayoutMode.freeform;
      _editMode = false;
      _selectedExposeWindowIds.clear();
    });
    _refreshWorkspaceViewTracking();
  }

  Future<void> _confirmApplyExposeGridToWorkspace() async {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null ||
        _screen != SerenityScreen.workspace ||
        _workspaceLayoutMode != WorkspaceLayoutMode.expose ||
        workspace.windows.isEmpty) {
      return;
    }

    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apply Grid?'),
          content: Text(
            'Replace the current freeform layout in "${workspace.name}" with this expose grid arrangement?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Apply')),
          ],
        );
      },
    );

    if (shouldApply == true && mounted) {
      _applyExposeGridToWorkspace();
    }
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
    final openWorkspaces = _openWorkspaces;
    final tabCount = openWorkspaces.length + 1;
    if (tabCount == 0) {
      return;
    }

    final currentIndex = _screen == SerenityScreen.library
        ? 0
        : openWorkspaces.indexWhere((workspace) => workspace.id == _session!.activeWorkspaceId) + 1;
    final nextIndex = (currentIndex + direction) % tabCount;
    final safeIndex = nextIndex < 0 ? tabCount - 1 : nextIndex;

    if (safeIndex == 0) {
      unawaited(_showWorkspaceOverview());
      return;
    }

    final nextWorkspace = openWorkspaces[safeIndex - 1];
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

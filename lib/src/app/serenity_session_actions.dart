// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellSessionActions on _SerenityShellState {
  static const double _appliedExposeViewportZoomFactor = 0.0625;

  void _updateSession(SerenitySessionState nextSession) {
    setState(() {
      _persistenceState.session = nextSession;
    });
    _refreshWorkspaceViewTracking();
    unawaited(_syncWindowTitle());
    _queueSave();
  }

  void _replaceWorkspace(WorkspaceState nextWorkspace, {bool queueThumbnail = true}) {
    final session = _persistenceState.session!;
    _updateSession(SerenityWorkspaceMutations.replaceWorkspace(session, nextWorkspace));
    if (queueThumbnail) {
      _thumbnailRefreshState.dirtyWorkspaces.add(nextWorkspace.id);
    }
  }

  void _toggleExpose() {
    final nextWorkspaceLayoutMode = _uiState.workspaceLayoutMode == WorkspaceLayoutMode.expose
        ? WorkspaceLayoutMode.freeform
        : WorkspaceLayoutMode.expose;
    _showWorkspaceScreen(
      workspaceLayoutMode: nextWorkspaceLayoutMode,
      resetEditMode: nextWorkspaceLayoutMode != WorkspaceLayoutMode.expose,
      clearExposeSelection: nextWorkspaceLayoutMode != WorkspaceLayoutMode.expose,
    );
  }

  void _setPinnedHoverWindow(String? windowId) {
    if (_windowInteractionState.pinnedHoverWindowId == windowId) {
      return;
    }
    setState(() {
      _windowInteractionState.pinnedHoverWindowId = windowId;
    });
  }

  void _clearPinnedHoverWindow() {
    _setPinnedHoverWindow(null);
  }

  void _flashWindow(String windowId) {
    _windowInteractionState.windowFlashTimer?.cancel();
    setState(() {
      _windowInteractionState.flashedWindowId = windowId;
      _windowInteractionState.windowFlashNonce += 1;
    });
    _windowInteractionState.windowFlashTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || _windowInteractionState.flashedWindowId != windowId) {
        return;
      }
      setState(() {
        _windowInteractionState.flashedWindowId = null;
      });
    });
  }

  void _applyExposeGridToWorkspace() {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null ||
        _uiState.screen != SerenityScreen.workspace ||
        _uiState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
      return;
    }
    if (_workspaceViewportState.viewportSize.width <= 0 ||
        _workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      return;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
    final exposeLayouts = computeExposeLayoutRects(
      windows: sortedWindows,
      viewportSize: _workspaceViewportState.viewportSize,
    );
    if (exposeLayouts.isEmpty) {
      return;
    }

    final viewportCenter = _workspaceViewportState.viewportSize.center(Offset.zero);
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

    _showWorkspaceScreen();
  }

  Future<void> _confirmApplyExposeGridToWorkspace() async {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null ||
        _uiState.screen != SerenityScreen.workspace ||
        _uiState.workspaceLayoutMode != WorkspaceLayoutMode.expose ||
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
    if (_uiState.screen == SerenityScreen.workspace) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    final showingLibrary = _uiState.screen == SerenityScreen.library;
    if (showingLibrary) {
      _showWorkspaceScreen();
    } else {
      _showLibraryScreen();
    }
  }

  Future<void> _showWorkspaceOverview() async {
    if (_uiState.screen == SerenityScreen.workspace) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    _showLibraryScreen();
  }

  Future<void> _switchWorkspace(int direction) async {
    final openWorkspaces = _openWorkspaces;
    final tabCount = openWorkspaces.length + 1;
    if (tabCount == 0) {
      return;
    }

    final currentIndex = _uiState.screen == SerenityScreen.library
        ? 0
        : openWorkspaces.indexWhere((workspace) => workspace.id == _persistenceState.session!.activeWorkspaceId) + 1;
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
    final session = _persistenceState.session!;
    final currentWorkspaceId = session.activeWorkspaceId;
    if (currentWorkspaceId != workspaceId) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    final shouldPreserveExpose =
        _uiState.screen == SerenityScreen.workspace && _uiState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
    _updateSession(
      session.copyWith(
        activeWorkspaceId: workspaceId,
        workspaces: session.workspaces
            .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: true) : workspace)
            .toList(),
      ),
    );

    _showWorkspaceScreen(
      workspaceLayoutMode: shouldPreserveExpose ? WorkspaceLayoutMode.expose : WorkspaceLayoutMode.freeform,
    );
  }

  void _toggleExposeWindowSelected(String windowId) {
    setState(() {
      if (_windowInteractionState.selectedExposeWindowIds.contains(windowId)) {
        _windowInteractionState.selectedExposeWindowIds.remove(windowId);
      } else {
        _windowInteractionState.selectedExposeWindowIds.add(windowId);
      }
    });
  }

  void _clearExposeSelection() {
    if (_windowInteractionState.selectedExposeWindowIds.isEmpty) {
      return;
    }
    setState(() {
      _windowInteractionState.selectedExposeWindowIds.clear();
    });
  }
}

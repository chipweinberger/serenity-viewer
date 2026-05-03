// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/app_shell.dart';

extension _AppShellEnvironmentActions on _AppShellState {
  static const double _appliedExposeViewportZoomFactor = 0.0625;

  void _updateEnvironment(Environment nextEnvironment) {
    _environmentController.updateEnvironment(nextEnvironment);
  }

  void _replaceWorkspace(Workspace nextWorkspace, {bool queueThumbnail = true}) {
    _environmentController.replaceWorkspace(nextWorkspace, queueThumbnail: queueThumbnail);
  }

  void _toggleExpose() {
    _chromeController.toggleExpose();
  }

  void _setPinnedHoverWindow(String? windowId) {
    _workspaceController.setPinnedHoverWindow(windowId);
  }

  void _clearPinnedHoverWindow() {
    _setPinnedHoverWindow(null);
  }

  void _flashWindow(String windowId) {
    _workspaceController.flashWindow(windowId, mounted: mounted);
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
    final relaidOutById = <String, Window>{};
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
    if (_chromeController.isWorkspaceScreen) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    if (_chromeController.isLibraryScreen) {
      _showWorkspaceScreen();
    } else {
      _showLibraryScreen();
    }
  }

  Future<void> _showWorkspaceOverview() async {
    if (_chromeController.isWorkspaceScreen) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    _showLibraryScreen();
  }

  Future<void> _switchWorkspace(int direction) async {
    final openWorkspaces = _openWorkspaces;
    final target = _chromeController.workspaceSwitchTarget(
      openWorkspaces: openWorkspaces,
      activeWorkspaceId: _persistenceState.environment!.activeWorkspaceId,
      direction: direction,
    );
    if (target.showsLibrary) {
      unawaited(_showWorkspaceOverview());
      return;
    }

    unawaited(_setActiveWorkspace(target.workspaceId!));
  }

  Future<void> _setActiveWorkspace(String workspaceId) async {
    final environment = _persistenceState.environment!;
    final currentWorkspaceId = environment.activeWorkspaceId;
    if (currentWorkspaceId != workspaceId) {
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    }

    final shouldPreserveExpose = _chromeController.isExposeMode;
    _updateEnvironment(
      environment.copyWith(
        activeWorkspaceId: workspaceId,
        workspaces: environment.workspaces
            .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: true) : workspace)
            .toList(),
      ),
    );

    _showWorkspaceScreen(
      workspaceLayoutMode: shouldPreserveExpose ? WorkspaceLayoutMode.expose : WorkspaceLayoutMode.freeform,
    );
  }

  void _toggleExposeWindowSelected(String windowId) {
    _workspaceController.toggleExposeWindowSelected(windowId);
  }

  void _clearExposeSelection() {
    _workspaceController.clearExposeSelection();
  }
}

// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/app_shell.dart';

extension _AppShellWorkspaceManagementActions on _AppShellState {
  int _nextWorkspaceOrdinal() {
    var maxOrdinal = 0;
    final idPattern = RegExp(r'^ws-(\d+)$');
    final namePattern = RegExp(r'^Workspace (\d+)$');

    for (final workspace in _workspaces) {
      final idMatch = idPattern.firstMatch(workspace.id);
      if (idMatch != null) {
        maxOrdinal = math.max(maxOrdinal, int.parse(idMatch.group(1)!));
      }

      final nameMatch = namePattern.firstMatch(workspace.name);
      if (nameMatch != null) {
        maxOrdinal = math.max(maxOrdinal, int.parse(nameMatch.group(1)!));
      }
    }

    return maxOrdinal + 1;
  }

  void _toggleWorkspaceOpen(String workspaceId) {
    _workspaceController.toggleWorkspaceOpen(_persistenceState.environment!, workspaceId, _updateEnvironment);
  }

  Future<void> _renameWorkspace(String workspaceId) async {
    final workspaceMatches = _workspaces.where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final controller = TextEditingController(text: workspace.name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Workspace'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Workspace name'),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    final trimmedName = nextName?.trim();
    if (trimmedName == null || trimmedName.isEmpty || trimmedName == workspace.name) {
      return;
    }

    _replaceWorkspace(workspace.copyWith(name: trimmedName));
  }

  Future<void> _confirmDeleteWorkspace(String workspaceId) async {
    final environment = _persistenceState.environment;
    if (environment == null) {
      return;
    }

    final workspaceMatches = environment.workspaces.where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Workspace?'),
          content: Text('Delete "${workspace.name}"? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      _deleteWorkspace(workspaceId);
    }
  }

  void _deleteWorkspace(String workspaceId) {
    final environment = _persistenceState.environment;
    if (environment == null) {
      return;
    }

    final remainingWorkspaces = environment.workspaces.where((workspace) => workspace.id != workspaceId).toList();
    if (remainingWorkspaces.isEmpty) {
      final now = DateTime.now();
      final replacementWorkspace = WorkspaceState(
        id: _newId('ws'),
        name: 'Workspace 1',
        createdAt: now,
        lastViewedAt: now,
        views: 0,
        links: const [],
        windows: const [],
        isOpen: true,
        viewportCenterDx: defaultWorkspaceCenter.dx,
        viewportCenterDy: defaultWorkspaceCenter.dy,
        viewportZoom: 1,
      );
      _updateEnvironment(
        environment.copyWith(workspaces: [replacementWorkspace], activeWorkspaceId: replacementWorkspace.id),
      );
      _showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
      _queueThumbnailRefresh(replacementWorkspace.id, delay: Duration.zero);
      return;
    }

    final stillActive = remainingWorkspaces.any((workspace) => workspace.id == environment.activeWorkspaceId);
    final nextActiveWorkspace = stillActive
        ? remainingWorkspaces.firstWhere((workspace) => workspace.id == environment.activeWorkspaceId)
        : (remainingWorkspaces.firstWhere((workspace) => workspace.isOpen, orElse: () => remainingWorkspaces.first));

    final normalizedWorkspaces = remainingWorkspaces
        .map(
          (workspace) => !remainingWorkspaces.any((entry) => entry.isOpen)
              ? (workspace.id == nextActiveWorkspace.id ? workspace.copyWith(isOpen: true) : workspace)
              : workspace,
        )
        .toList();

    _updateEnvironment(
      environment.copyWith(workspaces: normalizedWorkspaces, activeWorkspaceId: nextActiveWorkspace.id),
    );

    if (_uiState.screen != SerenityScreen.library && nextActiveWorkspace.id != workspaceId) {
      _showWorkspaceScreen(resetEditMode: false);
    }
  }

  Future<bool> _confirmMoveSelectedWindows(WorkspaceState destinationWorkspace, int count) async {
    final noun = count == 1 ? 'window' : 'windows';
    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Move Selected Windows?'),
          content: Text('Move $count selected $noun to "${destinationWorkspace.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Move')),
          ],
        );
      },
    );

    return shouldMove == true;
  }

  Future<void> _moveSelectedExposeWindowsToWorkspace(String destinationWorkspaceId) async {
    final environment = _persistenceState.environment;
    final sourceWorkspace = _activeWorkspaceOrNull;
    if (!_workspaceController.canMoveSelectedWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
    )) {
      if (sourceWorkspace != null && destinationWorkspaceId == sourceWorkspace.id) {
        _showMessage('Choose a different tab to move those windows.');
      }
      return;
    }

    if (sourceWorkspace == null) {
      return;
    }

    if (environment == null) {
      return;
    }

    if (destinationWorkspaceId == sourceWorkspace.id) {
      _showMessage('Choose a different tab to move those windows.');
      return;
    }

    final destinationMatches = environment.workspaces.where((workspace) => workspace.id == destinationWorkspaceId);
    if (destinationMatches.isEmpty) {
      return;
    }

    final destinationWorkspace = destinationMatches.first;
    final selectedWindowCount = _workspaceController.selectedExposeWindowCount(sourceWorkspace);
    if (selectedWindowCount == 0) {
      _clearExposeSelection();
      return;
    }

    final shouldMove = await _confirmMoveSelectedWindows(destinationWorkspace, selectedWindowCount);
    if (!shouldMove || !mounted) {
      return;
    }

    _workspaceController.moveSelectedExposeWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
      updateEnvironment: _updateEnvironment,
      queueThumbnailRefresh: _queueThumbnailRefresh,
    );
  }

  Future<void> _confirmCloseTab(String workspaceId) async {
    final workspace = _workspaces.firstWhere((entry) => entry.id == workspaceId);
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Close Tab?'),
          content: Text('This will close "${workspace.name}" in the tab bar.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Close Tab')),
          ],
        );
      },
    );

    if (shouldClose == true && mounted) {
      _toggleWorkspaceOpen(workspaceId);
    }
  }

  void _reorderOpenWorkspace(String sourceWorkspaceId, String targetWorkspaceId) {
    _workspaceController.reorderOpenWorkspace(
      _persistenceState.environment,
      _workspaces,
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      updateEnvironment: _updateEnvironment,
    );
  }

  void _createWorkspace() {
    final environment = _persistenceState.environment!;
    final nextIndex = _nextWorkspaceOrdinal();
    final now = DateTime.now();
    final workspace = WorkspaceState(
      id: 'ws-$nextIndex',
      name: 'Workspace $nextIndex',
      createdAt: now,
      lastViewedAt: now,
      views: 0,
      links: const [],
      isOpen: true,
      viewportCenterDx: defaultWorkspaceCenter.dx,
      viewportCenterDy: defaultWorkspaceCenter.dy,
      viewportZoom: 1,
      windows: const [],
    );

    _updateEnvironment(
      environment.copyWith(workspaces: [workspace, ...environment.workspaces], activeWorkspaceId: workspace.id),
    );

    _showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
    _queueThumbnailRefresh(workspace.id, delay: Duration.zero);
  }

  void _handleShortcut(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_uiState.screen == SerenityScreen.library) {
        _showWorkspaceScreen(clearExposeSelection: false);
      } else if (_uiState.screen == SerenityScreen.workspace &&
          _uiState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
        _toggleExpose();
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (_uiState.screen == SerenityScreen.workspace && _uiState.workspaceLayoutMode == WorkspaceLayoutMode.expose) {
        _showWorkspaceScreen(clearExposeSelection: false);
      } else if (_uiState.screen == SerenityScreen.workspace) {
        unawaited(_toggleWorkspaceOverview());
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      unawaited(_switchWorkspace(-1));
    } else if (key == LogicalKeyboardKey.arrowRight) {
      unawaited(_switchWorkspace(1));
    } else if (key == LogicalKeyboardKey.space) {
      final focusedWindow = _focusedWindowOrNull();
      if (focusedWindow?.asset.type == AssetType.video) {
        _toggleVideoPlayback(focusedWindow!.asset.id);
      }
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_workspaceLinksController.shouldHandlePasteLinksShortcut(event)) {
      unawaited(_workspaceLinksController.pasteLinksFromClipboard());
      return KeyEventResult.handled;
    }

    final key = event.logicalKey;
    if ({
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.space,
    }.contains(key)) {
      _handleShortcut(key);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

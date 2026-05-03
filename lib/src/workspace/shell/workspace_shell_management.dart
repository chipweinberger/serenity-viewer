import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';

class WorkspaceShellManagementApi {
  WorkspaceShellManagementApi(this._controller);

  final WorkspaceShellController _controller;

  int _nextWorkspaceOrdinal() {
    var maxOrdinal = 0;
    final idPattern = RegExp(r'^ws-(\d+)$');
    final namePattern = RegExp(r'^Workspace (\d+)$');

    for (final workspace in _controller.workspaces()) {
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

  void toggleWorkspaceOpen(String workspaceId) {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    _controller.workspaceController.environment.toggleWorkspaceOpen(
      environment,
      workspaceId,
      _controller.updateEnvironment,
    );
  }

  Future<void> renameWorkspace(String workspaceId) async {
    final workspaceMatches = _controller.workspaces().where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final controller = TextEditingController(text: workspace.name);
    final nextName = await showDialog<String>(
      context: _controller.context(),
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

    _controller.replaceWorkspace(workspace.copyWith(name: trimmedName));
  }

  Future<void> confirmDeleteWorkspace(String workspaceId) async {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final workspaceMatches = environment.workspaces.where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final shouldDelete = await showDialog<bool>(
      context: _controller.context(),
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

    if (shouldDelete == true && _controller.mounted()) {
      deleteWorkspace(workspaceId);
    }
  }

  void deleteWorkspace(String workspaceId) {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final remainingWorkspaces = environment.workspaces.where((workspace) => workspace.id != workspaceId).toList();
    if (remainingWorkspaces.isEmpty) {
      final now = DateTime.now();
      final replacementWorkspace = Workspace(
        id: _controller.newId('ws'),
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
      _controller.updateEnvironment(
        environment.copyWith(workspaces: [replacementWorkspace], activeWorkspaceId: replacementWorkspace.id),
      );
      _controller.showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
      _controller.queueWorkspaceRefresh(replacementWorkspace.id, delay: Duration.zero);
      return;
    }

    final stillActive = remainingWorkspaces.any((workspace) => workspace.id == environment.activeWorkspaceId);
    final nextActiveWorkspace = stillActive
        ? remainingWorkspaces.firstWhere((workspace) => workspace.id == environment.activeWorkspaceId)
        : remainingWorkspaces.firstWhere((workspace) => workspace.isOpen, orElse: () => remainingWorkspaces.first);

    final normalizedWorkspaces = remainingWorkspaces
        .map(
          (workspace) => !remainingWorkspaces.any((entry) => entry.isOpen)
              ? (workspace.id == nextActiveWorkspace.id ? workspace.copyWith(isOpen: true) : workspace)
              : workspace,
        )
        .toList();

    _controller.updateEnvironment(
      environment.copyWith(workspaces: normalizedWorkspaces, activeWorkspaceId: nextActiveWorkspace.id),
    );

    if (_controller.chromeState.screen != SerenityScreen.library && nextActiveWorkspace.id != workspaceId) {
      _controller.showWorkspaceScreen(resetEditMode: false);
    }
  }

  Future<bool> _confirmMoveSelectedWindows(Workspace destinationWorkspace, int count) async {
    final noun = count == 1 ? 'window' : 'windows';
    final shouldMove = await showDialog<bool>(
      context: _controller.context(),
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

  Future<void> moveSelectedExposeWindowsToWorkspace(String destinationWorkspaceId) async {
    final environment = _controller.persistenceState.environment;
    final sourceWorkspace = _controller.activeWorkspace();
    if (!_controller.workspaceController.environment.canMoveSelectedWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
    )) {
      if (sourceWorkspace != null && destinationWorkspaceId == sourceWorkspace.id) {
        _controller.showMessage('Choose a different tab to move those windows.');
      }
      return;
    }

    if (sourceWorkspace == null || environment == null) {
      return;
    }

    if (destinationWorkspaceId == sourceWorkspace.id) {
      _controller.showMessage('Choose a different tab to move those windows.');
      return;
    }

    final destinationMatches = environment.workspaces.where((workspace) => workspace.id == destinationWorkspaceId);
    if (destinationMatches.isEmpty) {
      return;
    }

    final destinationWorkspace = destinationMatches.first;
    final selectedWindowCount = _controller.workspaceController.expose.selectedWindowCount(sourceWorkspace);
    if (selectedWindowCount == 0) {
      _controller.navigation.clearExposeSelection();
      return;
    }

    final shouldMove = await _confirmMoveSelectedWindows(destinationWorkspace, selectedWindowCount);
    if (!shouldMove || !_controller.mounted()) {
      return;
    }

    _controller.workspaceController.environment.moveSelectedExposeWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
      updateEnvironment: _controller.updateEnvironment,
      queueThumbnailRefresh: _controller.queueWorkspaceRefresh,
    );
  }

  Future<void> confirmCloseTab(String workspaceId) async {
    final workspaceMatches = _controller.workspaces().where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final shouldClose = await showDialog<bool>(
      context: _controller.context(),
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

    if (shouldClose == true && _controller.mounted()) {
      toggleWorkspaceOpen(workspaceId);
    }
  }

  void reorderOpenWorkspace(String sourceWorkspaceId, String targetWorkspaceId) {
    _controller.workspaceController.environment.reorderOpenWorkspace(
      _controller.persistenceState.environment,
      _controller.workspaces(),
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      updateEnvironment: _controller.updateEnvironment,
    );
  }

  void createWorkspace() {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final nextIndex = _nextWorkspaceOrdinal();
    final now = DateTime.now();
    final workspace = Workspace(
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

    _controller.updateEnvironment(
      environment.copyWith(workspaces: [workspace, ...environment.workspaces], activeWorkspaceId: workspace.id),
    );

    _controller.showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
    _controller.queueWorkspaceRefresh(workspace.id, delay: Duration.zero);
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/session/environment_api.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

class EnvironmentManagementActionDependencies {
  const EnvironmentManagementActionDependencies({
    required this.environmentStoreState,
    required this.appUiState,
    required this.workspaceController,
    required this.workspaces,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.showWorkspaceScreen,
    required this.newId,
    required this.queueWorkspaceRefresh,
  });

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WorkspaceController workspaceController;
  final List<Workspace> Function() workspaces;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final String Function(String prefix) newId;
  final SerenityQueueWorkspaceRefresh queueWorkspaceRefresh;
}

class EnvironmentManagementActions {
  const EnvironmentManagementActions(this._dependencies);

  final EnvironmentManagementActionDependencies _dependencies;

  int _nextWorkspaceOrdinal() {
    var maxOrdinal = 0;
    final idPattern = RegExp(r'^ws-(\d+)$');
    final namePattern = RegExp(r'^Workspace (\d+)$');

    for (final workspace in _dependencies.workspaces()) {
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

  void toggleOpen(String workspaceId) {
    final environment = _dependencies.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    _dependencies.workspaceController.environment.tabs.toggleOpen(
      environment,
      workspaceId,
      _dependencies.updateEnvironment,
    );
  }

  void rename(Workspace workspace, String nextName) {
    _dependencies.replaceWorkspace(workspace.copyWith(name: nextName));
  }

  void delete(String workspaceId) {
    final environment = _dependencies.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    final remainingWorkspaces = environment.workspaces.where((workspace) => workspace.id != workspaceId).toList();
    if (remainingWorkspaces.isEmpty) {
      final now = DateTime.now();
      final replacementWorkspace = Workspace(
        id: _dependencies.newId('ws'),
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
      _dependencies.updateEnvironment(
        environment.copyWith(workspaces: [replacementWorkspace], activeWorkspaceId: replacementWorkspace.id),
      );
      _dependencies.showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
      _dependencies.queueWorkspaceRefresh(replacementWorkspace.id, delay: Duration.zero);
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

    _dependencies.updateEnvironment(
      environment.copyWith(workspaces: normalizedWorkspaces, activeWorkspaceId: nextActiveWorkspace.id),
    );

    if (_dependencies.appUiState.screen != SerenityScreen.library && nextActiveWorkspace.id != workspaceId) {
      _dependencies.showWorkspaceScreen(resetEditMode: false);
    }
  }

  void moveSelectedToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
  }) {
    _dependencies.workspaceController.environment.windowTransfer.moveSelectedToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
      selectedWindowIds: _dependencies.workspaceController.expose.ids(),
      updateEnvironment: _dependencies.updateEnvironment,
      queueThumbnailRefresh: _dependencies.queueWorkspaceRefresh,
      clearExposeSelection: _dependencies.workspaceController.expose.clear,
    );
  }

  void reorderOpen(String sourceWorkspaceId, String targetWorkspaceId) {
    _dependencies.workspaceController.environment.tabs.reorderOpen(
      _dependencies.environmentStoreState.environment,
      _dependencies.workspaces(),
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      updateEnvironment: _dependencies.updateEnvironment,
    );
  }

  void create() {
    final environment = _dependencies.environmentStoreState.environment;
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

    _dependencies.updateEnvironment(
      environment.copyWith(workspaces: [workspace, ...environment.workspaces], activeWorkspaceId: workspace.id),
    );

    _dependencies.showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
    _dependencies.queueWorkspaceRefresh(workspace.id, delay: Duration.zero);
  }
}

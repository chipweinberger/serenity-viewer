import 'dart:math' as math;

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';

class WorkspaceShellManagementMutations {
  const WorkspaceShellManagementMutations(this.controller);

  final WorkspaceShellController controller;

  int nextWorkspaceOrdinal() {
    var maxOrdinal = 0;
    final idPattern = RegExp(r'^ws-(\d+)$');
    final namePattern = RegExp(r'^Workspace (\d+)$');

    for (final workspace in controller.workspaces()) {
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
    final environment = controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    controller.workspaceController.environment.toggleWorkspaceOpen(
      environment,
      workspaceId,
      controller.updateEnvironment,
    );
  }

  void renameWorkspace(Workspace workspace, String nextName) {
    controller.replaceWorkspace(workspace.copyWith(name: nextName));
  }

  void deleteWorkspace(String workspaceId) {
    final environment = controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final remainingWorkspaces = environment.workspaces.where((workspace) => workspace.id != workspaceId).toList();
    if (remainingWorkspaces.isEmpty) {
      final now = DateTime.now();
      final replacementWorkspace = Workspace(
        id: controller.newId('ws'),
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
      controller.updateEnvironment(
        environment.copyWith(workspaces: [replacementWorkspace], activeWorkspaceId: replacementWorkspace.id),
      );
      controller.showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
      controller.queueWorkspaceRefresh(replacementWorkspace.id, delay: Duration.zero);
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

    controller.updateEnvironment(
      environment.copyWith(workspaces: normalizedWorkspaces, activeWorkspaceId: nextActiveWorkspace.id),
    );

    if (controller.chromeState.screen != SerenityScreen.library && nextActiveWorkspace.id != workspaceId) {
      controller.showWorkspaceScreen(resetEditMode: false);
    }
  }

  void moveSelectedExposeWindowsToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
  }) {
    controller.workspaceController.environment.moveSelectedExposeWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
      updateEnvironment: controller.updateEnvironment,
      queueThumbnailRefresh: controller.queueWorkspaceRefresh,
    );
  }

  void reorderOpenWorkspace(String sourceWorkspaceId, String targetWorkspaceId) {
    controller.workspaceController.environment.reorderOpenWorkspace(
      controller.persistenceState.environment,
      controller.workspaces(),
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      updateEnvironment: controller.updateEnvironment,
    );
  }

  void createWorkspace() {
    final environment = controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final nextIndex = nextWorkspaceOrdinal();
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

    controller.updateEnvironment(
      environment.copyWith(workspaces: [workspace, ...environment.workspaces], activeWorkspaceId: workspace.id),
    );

    controller.showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false);
    controller.queueWorkspaceRefresh(workspace.id, delay: Duration.zero);
  }
}

import 'dart:math' as math;

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/window/workspace_window_model_helpers.dart';

class WorkspaceEnvironmentMutations {
  static Environment replaceWorkspace(Environment environment, Workspace nextWorkspace) {
    return environment.copyWith(
      workspaces: environment.workspaces
          .map((workspace) => workspace.id == nextWorkspace.id ? nextWorkspace : workspace)
          .toList(),
    );
  }

  static Environment toggleWorkspaceOpen(Environment environment, String workspaceId) {
    final nextWorkspaces = environment.workspaces
        .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: !workspace.isOpen) : workspace)
        .toList();

    var nextActiveId = environment.activeWorkspaceId;
    final openWorkspaces = nextWorkspaces.where((workspace) => workspace.isOpen).toList();
    if (openWorkspaces.isEmpty) {
      nextWorkspaces[0] = nextWorkspaces[0].copyWith(isOpen: true);
      nextActiveId = nextWorkspaces[0].id;
    } else if (!openWorkspaces.any((workspace) => workspace.id == nextActiveId)) {
      nextActiveId = openWorkspaces.first.id;
    }

    return environment.copyWith(workspaces: nextWorkspaces, activeWorkspaceId: nextActiveId);
  }

  static List<Workspace> reorderOpenWorkspaces(
    List<Workspace> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
  }) {
    if (sourceWorkspaceId == targetWorkspaceId) {
      return workspaces;
    }

    final openWorkspaces = workspaces.where((workspace) => workspace.isOpen).toList();
    final sourceIndex = openWorkspaces.indexWhere((workspace) => workspace.id == sourceWorkspaceId);
    final targetIndex = openWorkspaces.indexWhere((workspace) => workspace.id == targetWorkspaceId);
    if (sourceIndex == -1 || targetIndex == -1) {
      return workspaces;
    }

    final moved = openWorkspaces.removeAt(sourceIndex);
    openWorkspaces.insert(targetIndex, moved);

    final openWorkspaceIds = openWorkspaces.map((workspace) => workspace.id).toList();
    final openWorkspaceById = {for (final workspace in openWorkspaces) workspace.id: workspace};
    var openWorkspaceCursor = 0;
    return workspaces.map((workspace) {
      if (!workspace.isOpen) {
        return workspace;
      }

      final nextWorkspaceId = openWorkspaceIds[openWorkspaceCursor++];
      return openWorkspaceById[nextWorkspaceId]!;
    }).toList();
  }

  static Environment moveWindowsToWorkspace(
    Environment environment, {
    required String sourceWorkspaceId,
    required String destinationWorkspaceId,
    required Set<String> windowIds,
  }) {
    if (windowIds.isEmpty || sourceWorkspaceId == destinationWorkspaceId) {
      return environment;
    }

    final sourceWorkspace = WorkspaceWindowModelHelpers.workspaceById(environment, sourceWorkspaceId);
    final destinationWorkspace = WorkspaceWindowModelHelpers.workspaceById(environment, destinationWorkspaceId);
    if (sourceWorkspace == null || destinationWorkspace == null) {
      return environment;
    }

    final movedSourceWindows = sourceWorkspace.windows.where((window) => windowIds.contains(window.asset.id)).toList();
    if (movedSourceWindows.isEmpty) {
      return environment;
    }

    var nextZ = destinationWorkspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    final movedWindows = movedSourceWindows.map((window) {
      nextZ += 1;
      return window.copyWith(zIndex: nextZ);
    }).toList();

    final nextWorkspaces = environment.workspaces.map((workspace) {
      if (workspace.id == sourceWorkspaceId) {
        return workspace.copyWith(
          windows: workspace.windows.where((window) => !windowIds.contains(window.asset.id)).toList(),
        );
      }
      if (workspace.id == destinationWorkspaceId) {
        return workspace.copyWith(windows: [...workspace.windows, ...movedWindows], isOpen: true);
      }
      return workspace;
    }).toList();

    return environment.copyWith(workspaces: nextWorkspaces);
  }
}

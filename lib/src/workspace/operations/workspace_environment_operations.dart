import 'dart:math' as math;

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_state_helpers.dart';

class WorkspaceEnvironmentOperations {
  static Environment replaceWorkspace(Environment environment, WorkspaceState nextWorkspace) {
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

  static List<WorkspaceState> reorderOpenWorkspaces(
    List<WorkspaceState> workspaces, {
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

  static Environment moveSelectedWindowsToWorkspace(
    Environment environment, {
    required String sourceWorkspaceId,
    required String destinationWorkspaceId,
    required Set<String> selectedWindowIds,
  }) {
    if (selectedWindowIds.isEmpty || sourceWorkspaceId == destinationWorkspaceId) {
      return environment;
    }

    final sourceWorkspace = WorkspaceStateHelpers.workspaceById(environment, sourceWorkspaceId);
    final destinationWorkspace = WorkspaceStateHelpers.workspaceById(environment, destinationWorkspaceId);
    if (sourceWorkspace == null || destinationWorkspace == null) {
      return environment;
    }

    final selectedWindows = sourceWorkspace.windows
        .where((window) => selectedWindowIds.contains(window.asset.id))
        .toList();
    if (selectedWindows.isEmpty) {
      return environment;
    }

    var nextZ = destinationWorkspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    final movedWindows = selectedWindows.map((window) {
      nextZ += 1;
      return window.copyWith(zIndex: nextZ);
    }).toList();

    final nextWorkspaces = environment.workspaces.map((workspace) {
      if (workspace.id == sourceWorkspaceId) {
        return workspace.copyWith(
          windows: workspace.windows.where((window) => !selectedWindowIds.contains(window.asset.id)).toList(),
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

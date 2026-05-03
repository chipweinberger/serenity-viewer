part of 'workspace_mutations.dart';

WorkspaceState? _workspaceById(Environment environment, String workspaceId) {
  return environment.workspaces.where((workspace) => workspace.id == workspaceId).firstOrNull;
}

WorkspaceWindowState? _windowById(WorkspaceState workspace, String windowId) {
  return workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
}

WorkspaceState _mapWindows(
  WorkspaceState workspace,
  WorkspaceWindowState Function(WorkspaceWindowState window) transform,
) {
  return workspace.copyWith(windows: workspace.windows.map(transform).toList());
}

WorkspaceState _updateWindowById(
  WorkspaceState workspace,
  String windowId,
  WorkspaceWindowState Function(WorkspaceWindowState window) transform,
) {
  return _mapWindows(workspace, (window) => window.asset.id == windowId ? transform(window) : window);
}

Environment _toggleWorkspaceOpen(Environment environment, String workspaceId) {
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

List<WorkspaceState> _reorderOpenWorkspaces(
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

Environment _moveSelectedWindowsToWorkspace(
  Environment environment, {
  required String sourceWorkspaceId,
  required String destinationWorkspaceId,
  required Set<String> selectedWindowIds,
}) {
  if (selectedWindowIds.isEmpty || sourceWorkspaceId == destinationWorkspaceId) {
    return environment;
  }

  final sourceWorkspace = _workspaceById(environment, sourceWorkspaceId);
  final destinationWorkspace = _workspaceById(environment, destinationWorkspaceId);
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

({WorkspaceState workspace, int? previousZOrder}) _focusWindow(WorkspaceState workspace, String windowId) {
  final currentWindow = _windowById(workspace, windowId);
  if (currentWindow == null) {
    return (workspace: workspace, previousZOrder: null);
  }

  final maxZ = workspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
  if (currentWindow.zIndex == maxZ) {
    return (workspace: workspace, previousZOrder: null);
  }

  return (
    workspace: _updateWindowById(workspace, windowId, (window) => window.copyWith(zIndex: maxZ + 1)),
    previousZOrder: currentWindow.zIndex,
  );
}

WorkspaceState _restorePreviousWindowZOrder(WorkspaceState workspace, String windowId, int previousZOrder) {
  final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  final currentIndex = sortedWindows.indexWhere((window) => window.asset.id == windowId);
  if (currentIndex == -1) {
    return workspace;
  }

  final targetWindow = sortedWindows.removeAt(currentIndex);
  var insertIndex = sortedWindows.indexWhere((window) => window.zIndex > previousZOrder);
  if (insertIndex == -1) {
    insertIndex = sortedWindows.length;
  }
  sortedWindows.insert(insertIndex, targetWindow);

  final reindexedWindows = sortedWindows
      .asMap()
      .entries
      .map((entry) => entry.value.copyWith(zIndex: entry.key + 1))
      .toList();
  final reindexedById = {for (final window in reindexedWindows) window.asset.id: window};

  return workspace.copyWith(
    windows: workspace.windows.map((window) => reindexedById[window.asset.id] ?? window).toList(),
  );
}

WorkspaceWindowState? _videoWindowById(WorkspaceState workspace, String windowId) {
  final window = _windowById(workspace, windowId);
  if (window == null || window.asset.type != AssetType.video) {
    return null;
  }
  return window;
}

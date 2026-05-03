import 'dart:math' as math;

import 'package:serenity_viewer/src/environment/workspace_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_state_helpers.dart';

class WorkspaceStackingOperations {
  static ({WorkspaceState workspace, int? previousZOrder}) focusWindow(WorkspaceState workspace, String windowId) {
    final currentWindow = WorkspaceStateHelpers.windowById(workspace, windowId);
    if (currentWindow == null) {
      return (workspace: workspace, previousZOrder: null);
    }

    final maxZ = workspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    if (currentWindow.zIndex == maxZ) {
      return (workspace: workspace, previousZOrder: null);
    }

    return (
      workspace: WorkspaceStateHelpers.updateWindowById(
        workspace,
        windowId,
        (window) => window.copyWith(zIndex: maxZ + 1),
      ),
      previousZOrder: currentWindow.zIndex,
    );
  }

  static WorkspaceState restorePreviousWindowZOrder(WorkspaceState workspace, String windowId, int previousZOrder) {
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
}

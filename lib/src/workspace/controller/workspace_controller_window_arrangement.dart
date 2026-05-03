import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_stacking_operations.dart';

import 'workspace_controller.dart';
import 'workspace_controller_windows.dart';

class WorkspaceWindowArrangementState {
  const WorkspaceWindowArrangementState({required this.chromeState, required this.replaceWorkspace});

  final ChromeState chromeState;
  final SerenityWorkspaceReplace replaceWorkspace;

  Window? focusedWindowOrNull(Workspace? workspace) {
    if (workspace == null || workspace.windows.isEmpty) {
      return null;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sortedWindows.last;
  }

  WindowFocusResult? focusWindow(Workspace workspace, String windowId) {
    final result = WorkspaceStackingOperations.focusWindow(workspace, windowId);
    if (identical(result.workspace, workspace)) {
      return null;
    }

    replaceWorkspace(result.workspace, queueThumbnail: true);
    return WindowFocusResult(previousZOrder: result.previousZOrder);
  }

  void restorePreviousWindowZOrder(Workspace workspace, String windowId, int previousZOrder) {
    replaceWorkspace(
      WorkspaceStackingOperations.restorePreviousWindowZOrder(workspace, windowId, previousZOrder),
      queueThumbnail: true,
    );
  }

  bool canCollateWorkspaceWindows(Workspace? workspace) {
    return workspace != null &&
        chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose &&
        workspace.windows.any((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video);
  }

  int collatableWindowCount(Workspace workspace) {
    return workspace.windows
        .where((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video)
        .length;
  }

  void collateWorkspaceWindows(Workspace workspace) {
    replaceWorkspace(
      WorkspaceLayout.collateWorkspaceWindows(workspace, targetBox: workspaceCollateTargetBox),
      queueThumbnail: true,
    );
  }
}

class WindowFocusResult {
  const WindowFocusResult({required this.previousZOrder});

  final int? previousZOrder;
}

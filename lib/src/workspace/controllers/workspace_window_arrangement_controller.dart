import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/mutations/workspace_stacking_mutations.dart';

import 'workspace_controller.dart';
import 'workspace_windows_controller.dart';

class WorkspaceWindowArrangementController {
  const WorkspaceWindowArrangementController({required this.appUiState, required this.replaceWorkspace});

  final AppUiState appUiState;
  final SerenityWorkspaceReplace replaceWorkspace;

  Window? focusedOrNull(Workspace? workspace) {
    if (workspace == null || workspace.windows.isEmpty) {
      return null;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sortedWindows.last;
  }

  WindowFocusResult? focus(Workspace workspace, String windowId) {
    final result = WorkspaceStackingMutations.focusWindow(workspace, windowId);
    if (identical(result.workspace, workspace)) {
      return null;
    }

    replaceWorkspace(result.workspace, queueThumbnail: true);
    return WindowFocusResult(previousZOrder: result.previousZOrder);
  }

  void restorePreviousZOrder(Workspace workspace, String windowId, int previousZOrder) {
    replaceWorkspace(
      WorkspaceStackingMutations.restorePreviousWindowZOrder(workspace, windowId, previousZOrder),
      queueThumbnail: true,
    );
  }

  bool canCollate(Workspace? workspace) {
    return workspace != null &&
        appUiState.workspaceLayoutMode != WorkspaceLayoutMode.expose &&
        workspace.windows.any((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video);
  }

  int collatableCount(Workspace workspace) {
    return workspace.windows
        .where((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video)
        .length;
  }

  void collate(Workspace workspace) {
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

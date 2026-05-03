import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace_state.dart';
import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class WorkspaceStateHelpers {
  static WorkspaceState? workspaceById(Environment environment, String workspaceId) {
    return environment.workspaces.where((workspace) => workspace.id == workspaceId).firstOrNull;
  }

  static WorkspaceWindowState? windowById(WorkspaceState workspace, String windowId) {
    return workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
  }

  static WorkspaceState mapWindows(
    WorkspaceState workspace,
    WorkspaceWindowState Function(WorkspaceWindowState window) transform,
  ) {
    return workspace.copyWith(windows: workspace.windows.map(transform).toList());
  }

  static WorkspaceState updateWindowById(
    WorkspaceState workspace,
    String windowId,
    WorkspaceWindowState Function(WorkspaceWindowState window) transform,
  ) {
    return mapWindows(workspace, (window) => window.asset.id == windowId ? transform(window) : window);
  }

  static WorkspaceWindowState? videoWindowById(WorkspaceState workspace, String windowId) {
    final window = windowById(workspace, windowId);
    if (window == null || window.asset.type != AssetType.video) {
      return null;
    }
    return window;
  }
}

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class WorkspaceHelpers {
  static Workspace? workspaceById(Environment environment, String workspaceId) {
    return environment.workspaces.where((workspace) => workspace.id == workspaceId).firstOrNull;
  }

  static Window? windowById(Workspace workspace, String windowId) {
    return workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
  }

  static Workspace mapWindows(
    Workspace workspace,
    Window Function(Window window) transform,
  ) {
    return workspace.copyWith(windows: workspace.windows.map(transform).toList());
  }

  static Workspace updateWindowById(
    Workspace workspace,
    String windowId,
    Window Function(Window window) transform,
  ) {
    return mapWindows(workspace, (window) => window.asset.id == windowId ? transform(window) : window);
  }

  static Window? videoWindowById(Workspace workspace, String windowId) {
    final window = windowById(workspace, windowId);
    if (window == null || window.asset.type != AssetType.video) {
      return null;
    }
    return window;
  }
}

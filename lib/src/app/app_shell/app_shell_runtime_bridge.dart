import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime_foundation_factory.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime_workspace_factory.dart';

class AppShellRuntimeBridge {
  Future<void> refreshWorkspaceTracking() async {
    _refreshWorkspaceTracking?.call();
  }

  void markWorkspaceThumbnailDirty(String workspaceId) {
    _markWorkspaceThumbnailDirty?.call(workspaceId);
  }

  Future<void> syncWindowTitle() async {
    _syncWindowTitle?.call();
  }

  void bindFoundation(AppShellRuntimeFoundation foundation) {
    _syncWindowTitle = foundation.appShellPlatformBridge.syncWindowTitle;
  }

  void bindWorkspace(AppShellRuntimeWorkspace workspace) {
    _refreshWorkspaceTracking = workspace.workspaceShellController.tracking.refresh;
    _markWorkspaceThumbnailDirty = workspace.thumbnailController.markWorkspaceDirty;
  }

  void Function()? _refreshWorkspaceTracking;
  void Function(String workspaceId)? _markWorkspaceThumbnailDirty;
  void Function()? _syncWindowTitle;
}

import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';

class AppRuntimeBridge {
  Future<void> refreshWorkspaceTracking() async {
    _refreshWorkspaceTracking?.call();
  }

  void markWorkspaceThumbnailDirty(String workspaceId) {
    _markWorkspaceThumbnailDirty?.call(workspaceId);
  }

  Future<void> syncWindowTitle() async {
    _syncWindowTitle?.call();
  }

  void bindFoundation(AppFoundation foundation) {
    _syncWindowTitle = foundation.platformBridge.syncWindowTitle;
  }

  void bindWorkspace(AppWorkspaceServices workspace) {
    _refreshWorkspaceTracking = workspace.environmentSession.tracking.refresh;
    _markWorkspaceThumbnailDirty = workspace.thumbnailController.markWorkspaceDirty;
  }

  void Function()? _refreshWorkspaceTracking;
  void Function(String workspaceId)? _markWorkspaceThumbnailDirty;
  void Function()? _syncWindowTitle;
}

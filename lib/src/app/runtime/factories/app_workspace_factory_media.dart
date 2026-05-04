part of 'app_workspace_factory.dart';

_MediaFlows _createMediaFlows({
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
}) {
  final videoFrameExporter = VideoFrameExporter(mediaInspector: scope.media);
  final workspaceVideoConversionPrompts = WorkspaceVideoConversionPrompts(context: scope.app.context);
  final workspaceVideoConversionController = WorkspaceVideoConversionController(
    showMessage: scope.app.showMessage,
    mediaInspector: scope.media,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: scope.platform.createFileBookmark,
    activeWorkspace: scope.ws.activeWorkspace,
    replaceWorkspace: scope.env.replaceWorkspace,
    colorFromDigest: scope.ws.colorFromDigest,
    removePausedVideoWindow: (windowId) {
      scope.app.commitStateChange(() {
        scope.interactionState.pausedVideoWindows.remove(windowId);
      });
    },
  );
  final workspaceMediaImportController = WorkspaceMediaImportController(
    imageExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'],
    videoExtensions: const ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'],
    environmentStoreState: scope.envState,
    activeWorkspace: () => scope.ws.activeWorkspace()!,
    confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
    videoFrameExporter: videoFrameExporter,
    createFileBookmark: scope.platform.createFileBookmark,
    mediaInspector: scope.media,
    updateEnvironment: scope.store.updateEnvironment,
    thumbnailController: thumbnailController,
    showMessage: scope.app.showMessage,
  );

  return _MediaFlows(
    workspaceVideoConversionController: workspaceVideoConversionController,
    workspaceMediaImportController: workspaceMediaImportController,
  );
}

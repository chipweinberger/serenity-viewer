part of 'app_workspace_factory.dart';

WorkspaceVideoConversionController _createWorkspaceVideoConversionController({
  required _WorkspaceFactoryScope scope,
  required VideoFrameExporter videoFrameExporter,
  required WorkspaceVideoConversionPrompts workspaceVideoConversionPrompts,
}) {
  return WorkspaceVideoConversionController(
    showMessage: scope.app.showMessage,
    mediaInspector: scope.media,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: scope.platform.createFileBookmark,
    activeWorkspace: scope.ws.activeWorkspace,
    replaceWorkspace: scope.env.replaceWorkspace,
    colorFromDigest: scope.ws.colorFromDigest,
    removePausedVideoWindow: scope.interactionState.removePausedVideoWindow,
  );
}

WorkspaceMediaImportController _createWorkspaceMediaImportController({
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required VideoFrameExporter videoFrameExporter,
  required WorkspaceVideoConversionPrompts workspaceVideoConversionPrompts,
}) {
  return WorkspaceMediaImportController(
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
}

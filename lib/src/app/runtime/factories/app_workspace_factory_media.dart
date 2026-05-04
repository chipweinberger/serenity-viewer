import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';

import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';

WorkspaceVideoConversionController createWorkspaceVideoConversionController({
  required WorkspaceFactoryScope scope,
  required VideoFrameExporter videoFrameExporter,
  required WorkspaceVideoConversionPrompts workspaceVideoConversionPrompts,
}) {
  return WorkspaceVideoConversionController(
    showMessage: scope.showMessage,
    mediaInspector: scope.media,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: scope.platform.createFileBookmark,
    activeWorkspace: scope.activeWorkspace,
    replaceWorkspace: scope.replaceWorkspace,
    colorFromDigest: scope.colorFromDigest,
    removePausedVideoWindow: scope.interactionState.removePausedVideoWindow,
  );
}

WorkspaceMediaImportController createWorkspaceMediaImportController({
  required WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required VideoFrameExporter videoFrameExporter,
  required WorkspaceVideoConversionPrompts workspaceVideoConversionPrompts,
}) {
  return WorkspaceMediaImportController(
    imageExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'],
    videoExtensions: const ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'],
    environmentStoreState: scope.envState,
    activeWorkspace: () => scope.activeWorkspace()!,
    confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
    videoFrameExporter: videoFrameExporter,
    createFileBookmark: scope.platform.createFileBookmark,
    mediaInspector: scope.media,
    updateEnvironment: scope.store.updateEnvironment,
    thumbnailController: thumbnailController,
    showMessage: scope.showMessage,
  );
}

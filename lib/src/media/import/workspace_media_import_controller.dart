// ignore_for_file: invalid_use_of_protected_member

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
import 'package:serenity_viewer/src/media/import/import_coordinator.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';

class WorkspaceMediaImportController {
  const WorkspaceMediaImportController({
    required this.imageExtensions,
    required this.videoExtensions,
    required this.environmentStoreState,
    required this.activeWorkspace,
    required this.workspaceVideoConversionController,
    required this.createFileBookmark,
    required this.mediaInspector,
    required this.updateEnvironment,
    required this.thumbnailController,
    required this.showMessage,
  });

  final List<String> imageExtensions;
  final List<String> videoExtensions;
  final EnvironmentStoreState environmentStoreState;
  final Workspace Function() activeWorkspace;
  final WorkspaceVideoConversionController workspaceVideoConversionController;
  final Future<String?> Function(String path) createFileBookmark;
  final MediaInspector mediaInspector;
  final ValueChanged<Environment> updateEnvironment;
  final ThumbnailController thumbnailController;
  final ValueChanged<String> showMessage;

  List<XTypeGroup> get acceptedTypeGroups {
    return [
      XTypeGroup(label: 'Media', extensions: [...imageExtensions, ...videoExtensions]),
    ];
  }

  Future<void> importFiles(List<XFile> files) async {
    final environment = environmentStoreState.environment;
    if (files.isEmpty || environment == null) {
      return;
    }

    final workspace = activeWorkspace();
    final result = await _buildImportCoordinator().importFiles(
      environment: environment,
      workspace: workspace,
      files: files,
    );

    if (!result.hadSupportedFiles) {
      showMessage('No supported image or video files were found in that selection.');
      return;
    }

    if (result.importedCount > 0) {
      updateEnvironment(result.environment);
      thumbnailController.queueWorkspaceRefresh(workspace.id);
    }
    if (result.skippedDuplicateCount > 0) {
      showMessage(
        'Skipped ${result.skippedDuplicateCount} duplicate asset'
        '${result.skippedDuplicateCount == 1 ? '' : 's'} already in this workspace.',
      );
    }
  }

  ImportCoordinator _buildImportCoordinator() {
    return ImportCoordinator(
      imageExtensions: imageExtensions,
      videoExtensions: videoExtensions,
      confirmSingleFrameConversion: workspaceVideoConversionController.confirmSingleFrameConversion,
      exportVideoFrameToJpeg: ({required sourcePath, required probe, positionMs}) {
        return workspaceVideoConversionController.exportVideoFrameToJpeg(
          sourcePath: sourcePath,
          probe: probe,
          positionMs: positionMs,
        );
      },
      createFileBookmark: createFileBookmark,
      md5ForFile: mediaInspector.md5ForFile,
      imageDimensionsForFile: mediaInspector.imageDimensionsForFile,
      videoDurationMsForFile: mediaInspector.videoDurationMsForFile,
      probeVideoFile: mediaInspector.probeVideoFile,
      newId: newSerenityId,
      colorFromDigest: assetColorValueFromDigest,
    );
  }
}

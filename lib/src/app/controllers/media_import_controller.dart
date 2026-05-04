// ignore_for_file: invalid_use_of_protected_member

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/media/import/import_coordinator.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/media/video/media_bridge.dart';
import 'package:serenity_viewer/src/media/video/video_conversion_coordinator.dart';

class MediaImportController {
  const MediaImportController({
    required this.imageExtensions,
    required this.videoExtensions,
    required this.environmentStoreState,
    required this.activeWorkspace,
    required this.videoConversionCoordinator,
    required this.createFileBookmark,
    required this.mediaBridge,
    required this.newId,
    required this.colorFromDigest,
    required this.updateEnvironment,
    required this.thumbnailController,
    required this.showMessage,
  });

  final List<String> imageExtensions;
  final List<String> videoExtensions;
  final EnvironmentStoreState environmentStoreState;
  final Workspace Function() activeWorkspace;
  final VideoConversionCoordinator videoConversionCoordinator;
  final Future<String?> Function(String path) createFileBookmark;
  final MediaBridge mediaBridge;
  final String Function(String prefix) newId;
  final int Function(String value) colorFromDigest;
  final ValueChanged<Environment> updateEnvironment;
  final ThumbnailController thumbnailController;
  final ValueChanged<String> showMessage;

  Future<void> pickAndImportAssets() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(label: 'Media', extensions: [...imageExtensions, ...videoExtensions]),
      ],
    );

    await importFiles(files);
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
      confirmSingleFrameConversion: videoConversionCoordinator.confirmSingleFrameConversion,
      exportVideoFrameToJpeg: ({required sourcePath, required probe, positionMs}) {
        return videoConversionCoordinator.exportVideoFrameToJpeg(
          sourcePath: sourcePath,
          probe: probe,
          positionMs: positionMs,
        );
      },
      createFileBookmark: createFileBookmark,
      md5ForFile: mediaBridge.md5ForFile,
      imageDimensionsForFile: mediaBridge.imageDimensionsForFile,
      videoDurationMsForFile: mediaBridge.videoDurationMsForFile,
      probeVideoFile: mediaBridge.probeVideoFile,
      newId: newId,
      colorFromDigest: colorFromDigest,
    );
  }
}

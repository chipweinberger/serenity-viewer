// ignore_for_file: invalid_use_of_protected_member

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
import 'package:serenity_viewer/src/media/import/import_coordinator.dart';
import 'package:serenity_viewer/src/media/import/import_result.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';

class WorkspaceMediaImportController {
  const WorkspaceMediaImportController({
    required this.imageExtensions,
    required this.videoExtensions,
    required this.appUiState,
    required this.environmentStoreState,
    required this.activeWorkspace,
    required this.confirmSingleFrameConversion,
    required this.videoFrameExporter,
    required this.createFileBookmark,
    required this.mediaInspector,
    required this.updateEnvironment,
    required this.thumbnailController,
    required this.showMessage,
  });

  final List<String> imageExtensions;
  final List<String> videoExtensions;
  final AppUiState appUiState;
  final EnvironmentStoreState environmentStoreState;
  final Workspace Function() activeWorkspace;
  final Future<bool> Function(String filename) confirmSingleFrameConversion;
  final VideoFrameExporter videoFrameExporter;
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

    final expandedFiles = await _expandImportFiles(files);
    if (expandedFiles.isEmpty) {
      showMessage('No supported image or video files were found in that selection.');
      return;
    }

    final workspace = activeWorkspace();
    appUiState.beginWorkspaceImport(expandedFiles.length);
    late final ImportResult result;
    try {
      result = await _buildImportCoordinator().importFiles(
        environment: environment,
        workspace: workspace,
        files: expandedFiles,
      );
    } finally {
      appUiState.endWorkspaceImport(expandedFiles.length);
    }

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

  Future<List<XFile>> _expandImportFiles(List<XFile> files) async {
    final expandedFiles = <XFile>[];
    final seenPaths = <String>{};

    Future<void> addFilePath(String path) async {
      final absolutePath = File(path).absolute.path;
      if (!seenPaths.add(absolutePath)) {
        return;
      }
      expandedFiles.add(XFile(absolutePath));
    }

    for (final file in files) {
      final path = file.path;
      final entityType = await FileSystemEntity.type(path, followLinks: false);
      switch (entityType) {
        case FileSystemEntityType.file:
          await addFilePath(path);
        case FileSystemEntityType.directory:
          await for (final entity in Directory(path).list(recursive: true, followLinks: false)) {
            if (entity is File) {
              await addFilePath(entity.path);
            }
          }
        case FileSystemEntityType.link:
        case FileSystemEntityType.notFound:
        case FileSystemEntityType.pipe:
        case FileSystemEntityType.unixDomainSock:
          break;
      }
    }

    return expandedFiles;
  }

  ImportCoordinator _buildImportCoordinator() {
    return ImportCoordinator(
      imageExtensions: imageExtensions,
      videoExtensions: videoExtensions,
      confirmSingleFrameConversion: confirmSingleFrameConversion,
      exportVideoFrameToJpeg: videoFrameExporter.exportVideoFrameToJpeg,
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

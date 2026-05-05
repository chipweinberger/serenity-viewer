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
import 'package:serenity_viewer/src/media/import/import_path_expander.dart';
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

  Future<String?> _folderImportWorkspaceName(List<XFile> files, Workspace workspace) async {
    if (workspace.windows.isNotEmpty || files.length != 1) {
      return null;
    }

    final selectedPath = files.single.path;
    final entityType = await FileSystemEntity.type(selectedPath, followLinks: false);
    if (entityType != FileSystemEntityType.directory) {
      return null;
    }

    final normalizedPath = Directory(selectedPath).absolute.path;
    final folderName = normalizedPath.split(Platform.pathSeparator).last.trim();
    return folderName.isEmpty ? null : folderName;
  }

  Environment _renamedWorkspaceEnvironment(Environment environment, Workspace workspace, String nextName) {
    return environment.copyWith(
      workspaces: environment.workspaces
          .map((entry) => entry.id == workspace.id ? entry.copyWith(name: nextName) : entry)
          .toList(growable: false),
    );
  }

  Future<List<XFile>> _expandImportFiles(List<XFile> files) async {
    final expandedPaths = await expandImportPaths(files.map((file) => file.path));
    return expandedPaths.map(XFile.new).toList(growable: false);
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

  Future<void> importFiles(List<XFile> files) async {
    final environment = environmentStoreState.environment;
    if (files.isEmpty || environment == null) {
      return;
    }

    final workspace = activeWorkspace();
    final renamedWorkspaceName = await _folderImportWorkspaceName(files, workspace);
    final expandedFiles = await _expandImportFiles(files);
    if (expandedFiles.isEmpty) {
      showMessage('No supported image or video files were found in that selection.');
      return;
    }

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
      final nextEnvironment = renamedWorkspaceName == null
          ? result.environment
          : _renamedWorkspaceEnvironment(result.environment, workspace, renamedWorkspaceName);
      updateEnvironment(nextEnvironment);
      thumbnailController.queueWorkspaceRefresh(workspace.id);
    }
    if (result.skippedDuplicateCount > 0) {
      showMessage(
        'Skipped ${result.skippedDuplicateCount} duplicate asset'
        '${result.skippedDuplicateCount == 1 ? '' : 's'} already in this workspace.',
      );
    }
  }
}

import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/media/importing/import_result.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/importing/import_window_layout.dart';
import 'package:serenity_viewer/src/workspace/windows/workspace_window_state.dart';
import 'package:serenity_viewer/src/environments/session/session_state.dart';
import 'package:serenity_viewer/src/media/conversion/settings_and_video_models.dart';
import 'package:serenity_viewer/src/media/assets/workspace_asset.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';

typedef SerenitySingleFrameConversionConfirmer = Future<bool> Function(String filename);
typedef SerenityVideoFrameExporter =
    Future<VideoConversionResult?> Function({
      required String sourcePath,
      required VideoProbeResult probe,
      int? positionMs,
    });
typedef SerenityFileBookmarkCreator = Future<String?> Function(String path);
typedef SerenityMd5Reader = Future<String> Function(File file);
typedef SerenityImageDimensionsReader = Future<Size?> Function(File file);
typedef SerenityVideoDurationReader = Future<int?> Function(File file);
typedef SerenityVideoProbeReader = Future<VideoProbeResult?> Function(File file);
typedef SerenityIdGenerator = String Function(String prefix);
typedef SerenityDigestColorResolver = int Function(String digest);

class SerenityImportCoordinator {
  SerenityImportCoordinator({
    required List<String> imageExtensions,
    required List<String> videoExtensions,
    required this.confirmSingleFrameConversion,
    required this.exportVideoFrameToJpeg,
    required this.createFileBookmark,
    required this.md5ForFile,
    required this.imageDimensionsForFile,
    required this.videoDurationMsForFile,
    required this.probeVideoFile,
    required this.newId,
    required this.colorFromDigest,
  }) : _imageExtensions = imageExtensions.map((value) => value.toLowerCase()).toSet(),
       _videoExtensions = videoExtensions.map((value) => value.toLowerCase()).toSet();

  static const int maxImportedFiles = 200;

  final Set<String> _imageExtensions;
  final Set<String> _videoExtensions;
  final SerenitySingleFrameConversionConfirmer confirmSingleFrameConversion;
  final SerenityVideoFrameExporter exportVideoFrameToJpeg;
  final SerenityFileBookmarkCreator createFileBookmark;
  final SerenityMd5Reader md5ForFile;
  final SerenityImageDimensionsReader imageDimensionsForFile;
  final SerenityVideoDurationReader videoDurationMsForFile;
  final SerenityVideoProbeReader probeVideoFile;
  final SerenityIdGenerator newId;
  final SerenityDigestColorResolver colorFromDigest;

  Future<SerenityImportResult> importFiles({
    required SerenitySessionState session,
    required WorkspaceState workspace,
    required List<XFile> files,
  }) async {
    final supported = files.where((file) => _assetTypeForPath(file.path) != null).toList();
    if (supported.isEmpty) {
      return SerenityImportResult(
        session: session,
        importedCount: 0,
        skippedDuplicateCount: 0,
        hadSupportedFiles: false,
      );
    }

    final limited = supported.take(maxImportedFiles).toList();
    var nextSession = session;
    final nextWindows = [...workspace.windows];
    final existingAssetDigests = nextWindows.map((window) => window.asset.md5).toSet();
    var nextZ = nextWindows.fold<int>(0, (value, item) => math.max(value, item.zIndex));
    var offsetIndex = 0;
    var skippedDuplicateCount = 0;
    var importedCount = 0;

    for (final xfile in limited) {
      final type = _assetTypeForPath(xfile.path);
      if (type == null) {
        continue;
      }

      final file = File(xfile.path);
      if (!await file.exists()) {
        continue;
      }

      final importedAsset = await _buildImportedAsset(
        file: file,
        xfile: xfile,
        type: type,
        workspace: workspace,
        offsetIndex: offsetIndex,
        nextZ: nextZ + 1,
        existingAssetDigests: existingAssetDigests,
      );
      if (importedAsset == null) {
        continue;
      }

      if (importedAsset.wasDuplicate) {
        skippedDuplicateCount += 1;
        continue;
      }

      final window = importedAsset.window!;
      nextSession = _recordFolder(nextSession, importedAsset.directory, weight: 2);
      nextWindows.add(window);
      existingAssetDigests.add(window.asset.md5);
      nextZ = window.zIndex;
      importedCount += 1;
      offsetIndex = (offsetIndex + 1) % 8;
    }

    if (importedCount == 0) {
      return SerenityImportResult(
        session: nextSession,
        importedCount: 0,
        skippedDuplicateCount: skippedDuplicateCount,
        hadSupportedFiles: true,
      );
    }

    final nextWorkspaces = nextSession.workspaces
        .map((entry) => entry.id == workspace.id ? entry.copyWith(windows: nextWindows, isOpen: true) : entry)
        .toList();

    return SerenityImportResult(
      session: nextSession.copyWith(workspaces: nextWorkspaces),
      importedCount: importedCount,
      skippedDuplicateCount: skippedDuplicateCount,
      hadSupportedFiles: true,
    );
  }

  AssetType? _assetTypeForPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return null;
    }

    final extension = path.substring(dotIndex + 1).toLowerCase();
    if (_imageExtensions.contains(extension)) {
      return AssetType.image;
    }
    if (_videoExtensions.contains(extension)) {
      return AssetType.video;
    }
    return null;
  }

  SerenitySessionState _recordFolder(SerenitySessionState session, String path, {int weight = 1}) {
    final normalized = Directory(path).absolute.path;
    final nextKnownFolders = [...session.knownFolders];
    if (!nextKnownFolders.contains(normalized)) {
      nextKnownFolders.add(normalized);
    }

    final nextPopularity = Map<String, int>.from(session.folderPopularity);
    nextPopularity[normalized] = (nextPopularity[normalized] ?? 0) + weight;
    return session.copyWith(knownFolders: nextKnownFolders, folderPopularity: nextPopularity);
  }

  Future<_PreparedImportedAsset?> _buildImportedAsset({
    required File file,
    required XFile xfile,
    required AssetType type,
    required WorkspaceState workspace,
    required int offsetIndex,
    required int nextZ,
    required Set<String> existingAssetDigests,
  }) async {
    final videoProbe = type == AssetType.video ? await probeVideoFile(file) : null;
    var importType = type;
    var importPath = xfile.path;
    var importFilename = xfile.name;
    String? importMd5;
    var videoDurationMs =
        videoProbe?.durationMs ?? (type == AssetType.video ? await videoDurationMsForFile(file) : null);
    var imageDimensions = type == AssetType.image ? await imageDimensionsForFile(file) : null;
    final videoDimensions = videoProbe?.width != null && videoProbe?.height != null
        ? Size(videoProbe!.width!.toDouble(), videoProbe.height!.toDouble())
        : null;

    if (type == AssetType.video && videoProbe?.isSingleFrame == true) {
      final shouldConvert = await confirmSingleFrameConversion(xfile.name);
      if (shouldConvert) {
        final conversion = await exportVideoFrameToJpeg(
          sourcePath: xfile.path,
          probe: videoProbe!,
          positionMs: videoDurationMs == null ? null : math.min(videoDurationMs, 1000),
        );
        if (conversion != null) {
          importType = AssetType.image;
          importPath = conversion.path;
          importFilename = conversion.filename;
          importMd5 = conversion.md5;
          imageDimensions = Size(conversion.width, conversion.height);
          videoDurationMs = null;
        }
      }
    }

    final importFile = File(importPath);
    final digest = importMd5 ?? await md5ForFile(importFile);
    if (existingAssetDigests.contains(digest)) {
      return const _PreparedImportedAsset.duplicate();
    }

    final fileBookmark = await createFileBookmark(importPath);
    final windowSize = importedAssetWindowSize(
      importType: importType,
      imageDimensions: imageDimensions,
      videoDimensions: videoDimensions,
    );
    final basePlacement = importedAssetWindowPosition(
      viewportCenter: workspace.viewportCenter,
      offsetIndex: offsetIndex,
      windowSize: windowSize,
    );
    final sourceFolderName = file.parent.path.split(Platform.pathSeparator).last;

    return _PreparedImportedAsset(
      directory: importFile.parent.path,
      window: AssetWindowState(
        asset: WorkspaceAsset(
          id: newId('asset'),
          filename: importFilename,
          md5: digest,
          type: importType,
          colorValue: colorFromDigest(digest),
          note: importedAssetNote(
            originalType: type,
            importType: importType,
            videoDurationMs: videoDurationMs,
            sourceFolderName: sourceFolderName,
          ),
          videoDurationMs: videoDurationMs,
          filePath: importPath,
          fileBookmark: fileBookmark,
          intrinsicWidth: importType == AssetType.video ? videoDimensions?.width : imageDimensions?.width,
          intrinsicHeight: importType == AssetType.video ? videoDimensions?.height : imageDimensions?.height,
        ),
        position: basePlacement,
        size: windowSize,
        zoom: 1,
        zIndex: nextZ,
      ),
    );
  }
}

class _PreparedImportedAsset {
  const _PreparedImportedAsset({required this.directory, required this.window}) : wasDuplicate = false;
  const _PreparedImportedAsset.duplicate() : directory = '', window = null, wasDuplicate = true;

  final String directory;
  final AssetWindowState? window;
  final bool wasDuplicate;
}

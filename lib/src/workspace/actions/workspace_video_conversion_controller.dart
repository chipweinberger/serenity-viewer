import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/window/content/asset_zoom_utils.dart';

class WorkspaceVideoConversionController {
  WorkspaceVideoConversionController({
    required this.showMessage,
    required this.mediaInspector,
    required this.videoFrameExporter,
    required this.videoConversionPrompts,
    required this.createFileBookmark,
    required this.activeWorkspace,
    required this.replaceWorkspace,
    required this.colorFromDigest,
    required this.removePausedVideoWindow,
  });

  final ValueChanged<String> showMessage;
  final MediaInspector mediaInspector;
  final VideoFrameExporter videoFrameExporter;
  final Future<bool> Function(String filename) videoConversionPrompts;
  final Future<String?> Function(String path) createFileBookmark;
  final Workspace? Function() activeWorkspace;
  final void Function(Workspace workspace) replaceWorkspace;
  final int Function(String value) colorFromDigest;
  final ValueChanged<String> removePausedVideoWindow;

  Future<void> convertWindowToJpeg(String windowId) async {
    final workspace = activeWorkspace();
    if (workspace == null) {
      return;
    }

    final matches = workspace.windows.where((window) => window.asset.id == windowId);
    if (matches.isEmpty) {
      showMessage('Focus a video or PNG window first.');
      return;
    }

    final window = matches.first;
    if (window.asset.type == AssetType.video) {
      await _convertVideoWindowToJpeg(workspace, window);
      return;
    }

    if (_isPngWindow(window)) {
      await _convertPngWindowToJpeg(workspace, window);
      return;
    }

    showMessage('Focus a video or PNG window first.');
  }

  Future<void> _convertVideoWindowToJpeg(Workspace workspace, Window window) async {
    final sourcePath = window.asset.filePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      showMessage('That video is missing its source file.');
      return;
    }
    final sourceFile = File(sourcePath);

    final probe = await mediaInspector.probeVideoFile(sourceFile);
    if (probe == null || probe.width == null || probe.height == null) {
      showMessage('Serenity could not inspect that video for conversion.');
      return;
    }

    final conversion = await videoFrameExporter.exportVideoFrameToJpeg(
      sourcePath: sourcePath,
      probe: probe,
      positionMs: window.videoPositionMs,
      normalizedCrop: normalizedVisibleRectForWindow(window, Size(probe.width!.toDouble(), probe.height!.toDouble())),
      confirmOverwriteJpeg: videoConversionPrompts,
    );
    if (conversion == null) {
      return;
    }

    final bookmark = await createFileBookmark(conversion.path);
    replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows
            .map(
              (entry) => entry.asset.id == window.asset.id
                  ? entry.copyWith(
                      zoom: 1,
                      clearZoomBase: true,
                      clearContentOffset: true,
                      asset: entry.asset.copyWith(
                        filename: conversion.filename,
                        md5: conversion.md5,
                        type: AssetType.image,
                        colorValue: colorFromDigest(conversion.md5),
                        note:
                            'Converted from video still in ${File(conversion.path).parent.path.split(Platform.pathSeparator).last}.',
                        videoDurationMs: null,
                        filePath: conversion.path,
                        fileBookmark: bookmark,
                        intrinsicWidth: conversion.width,
                        intrinsicHeight: conversion.height,
                      ),
                      videoPositionMs: null,
                    )
                  : entry,
            )
            .toList(),
      ),
    );

    removePausedVideoWindow(window.asset.id);
    showMessage('Converted ${window.asset.filename} to ${conversion.filename}.');
  }

  Future<void> _convertPngWindowToJpeg(Workspace workspace, Window window) async {
    final sourcePath = window.asset.filePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      showMessage('That PNG is missing its source file.');
      return;
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      showMessage('That PNG is missing its source file.');
      return;
    }

    final destinationPath = _jpegPathFor(sourceFile);
    final destinationFile = File(destinationPath);
    if (await destinationFile.exists()) {
      final shouldOverwrite = await videoConversionPrompts(destinationFile.uri.pathSegments.last);
      if (!shouldOverwrite) {
        return;
      }
    }

    final bytes = await sourceFile.readAsBytes();
    final decoded = img.decodePng(bytes);
    if (decoded == null) {
      showMessage('Serenity could not decode that PNG for conversion.');
      return;
    }

    await destinationFile.writeAsBytes(img.encodeJpg(decoded, quality: 92), flush: true);
    final md5 = await mediaInspector.md5ForFile(destinationFile);
    final dimensions = await mediaInspector.imageDimensionsForFile(destinationFile);
    final bookmark = await createFileBookmark(destinationPath);
    final filename = destinationFile.uri.pathSegments.last;

    replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows
            .map(
              (entry) => entry.asset.id == window.asset.id
                  ? entry.copyWith(
                      asset: entry.asset.copyWith(
                        filename: filename,
                        md5: md5,
                        type: AssetType.image,
                        colorValue: colorFromDigest(md5),
                        note:
                            'Converted from PNG in ${destinationFile.parent.path.split(Platform.pathSeparator).last}.',
                        videoDurationMs: null,
                        filePath: destinationPath,
                        fileBookmark: bookmark,
                        intrinsicWidth: dimensions?.width,
                        intrinsicHeight: dimensions?.height,
                      ),
                    )
                  : entry,
            )
            .toList(),
      ),
    );

    showMessage('Converted ${window.asset.filename} to $filename.');
  }

  bool _isPngWindow(Window window) {
    if (window.asset.type != AssetType.image) {
      return false;
    }

    final sourcePath = window.asset.filePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      return false;
    }

    return sourcePath.toLowerCase().endsWith('.png');
  }

  String _jpegPathFor(File sourceFile) {
    final sourcePath = sourceFile.path;
    final extensionIndex = sourcePath.lastIndexOf('.');
    final basePath = extensionIndex <= 0 ? sourcePath : sourcePath.substring(0, extensionIndex);
    return '$basePath.jpg';
  }
}

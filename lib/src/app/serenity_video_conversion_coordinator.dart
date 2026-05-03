import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/serenity_media_bridge.dart';
import 'package:serenity_viewer/src/app/serenity_session_persistence_bridge.dart';
import 'package:serenity_viewer/src/core/serenity_core.dart';
import 'package:serenity_viewer/src/models/session_support.dart';
import 'package:serenity_viewer/src/models/workspace_state.dart';
import 'package:serenity_viewer/src/widgets/serenity_media_zoom_utils.dart';

class SerenityVideoConversionCoordinator {
  SerenityVideoConversionCoordinator({
    required this.context,
    required this.mounted,
    required this.showMessage,
    required this.mediaBridge,
    required this.sessionPersistenceBridge,
    required this.activeWorkspace,
    required this.replaceWorkspace,
    required this.colorFromDigest,
    required this.removePausedVideoWindow,
  });

  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
  final SerenityMediaBridge mediaBridge;
  final SerenitySessionPersistenceBridge sessionPersistenceBridge;
  final WorkspaceState? Function() activeWorkspace;
  final void Function(WorkspaceState workspace) replaceWorkspace;
  final int Function(String value) colorFromDigest;
  final ValueChanged<String> removePausedVideoWindow;

  Future<bool> confirmOverwriteJpeg(String filename) async {
    final shouldOverwrite = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Replace Existing JPEG?'),
          content: Text('$filename already exists. Replace it?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Replace')),
          ],
        );
      },
    );

    return shouldOverwrite == true;
  }

  Future<bool> confirmSingleFrameConversion(String filename) async {
    final shouldConvert = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Single-Frame Video Detected'),
          content: Text('$filename appears to contain a single frame. Convert it to JPEG instead?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep Video')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Convert to JPEG')),
          ],
        );
      },
    );

    return shouldConvert == true;
  }

  Future<VideoConversionResult?> exportVideoFrameToJpeg({
    required String sourcePath,
    required VideoProbeResult probe,
    int? positionMs,
    Rect? normalizedCrop,
    bool promptBeforeOverwrite = true,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    final sourceWidth = probe.width;
    final sourceHeight = probe.height;
    if (sourceWidth == null || sourceHeight == null || sourceWidth <= 0 || sourceHeight <= 0) {
      return null;
    }

    final sourceName = sourceFile.uri.pathSegments.isEmpty ? 'frame.mov' : sourceFile.uri.pathSegments.last;
    final dotIndex = sourceName.lastIndexOf('.');
    final stem = dotIndex <= 0 ? sourceName : sourceName.substring(0, dotIndex);
    final outputPath = '${sourceFile.parent.path}${Platform.pathSeparator}$stem.jpg';
    final outputFile = File(outputPath);

    if (promptBeforeOverwrite && await outputFile.exists()) {
      final shouldOverwrite = await confirmOverwriteJpeg(outputFile.uri.pathSegments.last);
      if (!shouldOverwrite) {
        return null;
      }
    }

    final crop = normalizedCrop ?? const Rect.fromLTWH(0, 0, 1, 1);

    try {
      final result = await videoToolsChannel.invokeMapMethod<String, dynamic>('exportVideoFrameToJpeg', {
        'sourcePath': sourcePath,
        'destinationPath': outputPath,
        'positionMs': positionMs,
        'normalizedCrop': {'left': crop.left, 'top': crop.top, 'width': crop.width, 'height': crop.height},
      });
      if (result == null || !await outputFile.exists()) {
        return null;
      }
      final digest = await mediaBridge.md5ForFile(outputFile);
      final width = (result['width'] as num?)?.toDouble();
      final height = (result['height'] as num?)?.toDouble();
      final dimensions = width != null && height != null
          ? Size(width, height)
          : await mediaBridge.imageDimensionsForFile(outputFile);
      if (dimensions == null) {
        return null;
      }

      return VideoConversionResult(
        path: outputPath,
        filename: result['filename'] as String? ?? outputFile.uri.pathSegments.last,
        md5: digest,
        width: dimensions.width,
        height: dimensions.height,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> convertVideoWindowToJpeg(String windowId) async {
    final workspace = activeWorkspace();
    if (workspace == null) {
      return;
    }

    final matches = workspace.windows.where(
      (window) => window.asset.id == windowId && window.asset.type == AssetType.video,
    );
    if (matches.isEmpty) {
      showMessage('Focus a video window first.');
      return;
    }

    final window = matches.first;
    final sourcePath = window.asset.filePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      showMessage('That video is missing its source file.');
      return;
    }

    final probe = await mediaBridge.probeVideoFile(File(sourcePath));
    if (probe == null || probe.width == null || probe.height == null) {
      showMessage('Serenity could not inspect that video for conversion.');
      return;
    }

    final conversion = await exportVideoFrameToJpeg(
      sourcePath: sourcePath,
      probe: probe,
      positionMs: window.videoPositionMs,
      normalizedCrop: normalizedVisibleRectForWindow(window, Size(probe.width!.toDouble(), probe.height!.toDouble())),
    );
    if (conversion == null) {
      return;
    }

    final bookmark = await sessionPersistenceBridge.createFileBookmark(conversion.path);
    replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows
            .map(
              (entry) => entry.asset.id == windowId
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

    removePausedVideoWindow(windowId);
    showMessage('Converted ${window.asset.filename} to ${conversion.filename}.');
  }
}

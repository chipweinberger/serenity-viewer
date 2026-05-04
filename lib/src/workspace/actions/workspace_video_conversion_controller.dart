import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/window/content/asset_zoom_utils.dart';

class WorkspaceVideoConversionController {
  WorkspaceVideoConversionController({
    required this.context,
    required this.mounted,
    required this.showMessage,
    required this.mediaInspector,
    required this.videoFrameExporter,
    required this.createFileBookmark,
    required this.activeWorkspace,
    required this.replaceWorkspace,
    required this.colorFromDigest,
    required this.removePausedVideoWindow,
  });

  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
  final MediaInspector mediaInspector;
  final VideoFrameExporter videoFrameExporter;
  final Future<String?> Function(String path) createFileBookmark;
  final Workspace? Function() activeWorkspace;
  final void Function(Workspace workspace) replaceWorkspace;
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
      confirmOverwriteJpeg: confirmOverwriteJpeg,
    );
    if (conversion == null) {
      return;
    }

    final bookmark = await createFileBookmark(conversion.path);
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

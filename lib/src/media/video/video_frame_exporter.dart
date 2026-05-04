import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/video_models.dart';

typedef VideoFrameOverwriteConfirmer = Future<bool> Function(String filename);

class VideoFrameExporter {
  const VideoFrameExporter({required this.mediaInspector});

  final MediaInspector mediaInspector;

  Future<VideoConversionResult?> exportVideoFrameToJpeg({
    required String sourcePath,
    required VideoProbeResult probe,
    int? positionMs,
    Rect? normalizedCrop,
    bool promptBeforeOverwrite = true,
    VideoFrameOverwriteConfirmer? confirmOverwriteJpeg,
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
      final shouldOverwrite = await confirmOverwriteJpeg?.call(outputFile.uri.pathSegments.last) ?? false;
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
      final digest = await mediaInspector.md5ForFile(outputFile);
      final width = (result['width'] as num?)?.toDouble();
      final height = (result['height'] as num?)?.toDouble();
      final dimensions = width != null && height != null
          ? Size(width, height)
          : await mediaInspector.imageDimensionsForFile(outputFile);
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
}

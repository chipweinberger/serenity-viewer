// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityVideoConversionTools on _SerenityShellState {
  Future<bool> _confirmOverwriteJpeg(String filename) async {
    final shouldOverwrite = await showDialog<bool>(
      context: context,
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

  Future<bool> _confirmSingleFrameConversion(String filename) async {
    final shouldConvert = await showDialog<bool>(
      context: context,
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

  Future<VideoConversionResult?> _exportVideoFrameToJpeg({
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
      final shouldOverwrite = await _confirmOverwriteJpeg(outputFile.uri.pathSegments.last);
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
      final digest = await _md5ForFile(outputFile);
      final width = (result['width'] as num?)?.toDouble();
      final height = (result['height'] as num?)?.toDouble();
      final dimensions = width != null && height != null
          ? Size(width, height)
          : await _imageDimensionsForFile(outputFile);
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

  Future<void> _convertVideoWindowToJpeg(String windowId) async {
    final workspace = _activeWorkspaceOrNull;
    if (workspace == null) {
      return;
    }

    final matches = workspace.windows.where(
      (window) => window.asset.id == windowId && window.asset.type == AssetType.video,
    );
    if (matches.isEmpty) {
      _showMessage('Focus a video window first.');
      return;
    }

    final window = matches.first;
    final sourcePath = window.asset.filePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      _showMessage('That video is missing its source file.');
      return;
    }

    final probe = await _probeVideoFile(File(sourcePath));
    if (probe == null || probe.width == null || probe.height == null) {
      _showMessage('Serenity could not inspect that video for conversion.');
      return;
    }

    final conversion = await _exportVideoFrameToJpeg(
      sourcePath: sourcePath,
      probe: probe,
      positionMs: window.videoPositionMs,
      normalizedCrop: normalizedVisibleRectForWindow(window, Size(probe.width!.toDouble(), probe.height!.toDouble())),
    );
    if (conversion == null) {
      return;
    }

    final bookmark = await _createFileBookmark(conversion.path);
    _replaceWorkspace(
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
                        colorValue: _colorFromDigest(conversion.md5),
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

    setState(() {
      _windowInteractionState.pausedVideoWindows.remove(windowId);
    });
    _showMessage('Converted ${window.asset.filename} to ${conversion.filename}.');
  }
}

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:serenity_viewer/src/asset_window/content/asset_zoom_utils.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_projection.dart';

class ThumbnailRenderer {
  ThumbnailRenderer({required this.isRunningInWidgetTest});

  final bool isRunningInWidgetTest;

  Future<Uint8List?> buildThumbnailBytes({required Workspace workspace, required Size viewportSize}) async {
    const canvasWidth = 560.0;
    const canvasHeight = 360.0;
    const assetCornerRadius = 12.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));
    canvas.drawColor(AppTheme.background, BlendMode.src);

    if (workspace.windows.isEmpty) {
      final emptyPaint = Paint()..color = AppTheme.background;
      canvas.drawRect(const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), emptyPaint);
    } else {
      final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
      final sourceViewportSize = viewportSize.width > 0 && viewportSize.height > 0
          ? viewportSize
          : const Size(canvasWidth, canvasHeight);
      final sourceScale = math.min(canvasWidth / sourceViewportSize.width, canvasHeight / sourceViewportSize.height);
      final sourceOffset = Offset(
        (canvasWidth - (sourceViewportSize.width * sourceScale)) / 2,
        (canvasHeight - (sourceViewportSize.height * sourceScale)) / 2,
      );
      for (final window in sortedWindows) {
        final rect = workspaceScreenRectForWindow(
          workspace,
          window,
          sourceViewportSize,
          viewportOffset: sourceOffset,
          viewportScale: sourceScale,
        );
        if (!rect.overlaps(const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight))) {
          continue;
        }

        final roundedRect = RRect.fromRectAndRadius(rect, const Radius.circular(assetCornerRadius));
        final mediaLayout = _thumbnailMediaLayoutForWindow(window: window, windowRect: rect);
        canvas.save();
        try {
          canvas.clipRRect(roundedRect);
          canvas.drawRect(rect, Paint()..color = window.asset.color);

          var paintedMedia = false;
          if (window.asset.type == AssetType.image &&
              window.asset.filePath != null &&
              await File(window.asset.filePath!).exists()) {
            final decoded = await _decodeThumbnailSourceImage(window.asset.filePath!);
            if (decoded != null) {
              canvas.save();
              canvas.clipRect(rect);
              canvas.drawImageRect(
                decoded,
                Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
                mediaLayout.mediaRect,
                Paint()..filterQuality = FilterQuality.medium,
              );
              canvas.restore();
              paintedMedia = true;
            }
          } else if (window.asset.filePath != null && window.asset.filePath!.isNotEmpty) {
            final decoded = await _decodeThumbnailVideoFrame(window, targetWidth: rect.width.ceil());
            if (decoded != null && !mediaLayout.visibleRect.isEmpty) {
              canvas.drawImageRect(
                decoded,
                Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
                mediaLayout.visibleRect,
                Paint()..filterQuality = FilterQuality.medium,
              );
              paintedMedia = true;
            }
          }

          if (!paintedMedia) {
            canvas.drawRect(rect, Paint()..color = window.asset.color);
          }
        } finally {
          canvas.restore();
        }
      }
    }

    final image = await recorder.endRecording().toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    if (pngBytes == null) {
      return null;
    }

    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      return null;
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
  }

  Future<ui.Image?> _decodeThumbnailSourceImage(String path, {int targetWidth = 320}) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _decodeThumbnailVideoFrame(Window window, {int targetWidth = 320}) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    final path = window.asset.filePath;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      return null;
    }

    try {
      final sourceWidth = window.asset.intrinsicWidth;
      final sourceHeight = window.asset.intrinsicHeight;
      final normalizedCrop = sourceWidth != null && sourceHeight != null && sourceWidth > 0 && sourceHeight > 0
          ? normalizedVisibleRectForWindow(window, Size(sourceWidth, sourceHeight))
          : const Rect.fromLTWH(0, 0, 1, 1);
      final bytes = await videoToolsChannel.invokeMethod<Uint8List>('renderVideoThumbnail', {
        'sourcePath': path,
        'positionMs': window.videoPositionMs ?? 0,
        'targetWidth': targetWidth,
        'normalizedCrop': {
          'left': normalizedCrop.left,
          'top': normalizedCrop.top,
          'width': normalizedCrop.width,
          'height': normalizedCrop.height,
        },
      });
      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  ({Rect mediaRect, Rect visibleRect}) _thumbnailMediaLayoutForWindow({
    required Window window,
    required Rect windowRect,
  }) {
    final scale = window.size.width <= 0 ? 1.0 : windowRect.width / window.size.width;
    final fitSize = fitSizeForViewportToAspect(windowRect.size, window.asset.aspectRatio);
    final baseSize = window.zoom > 1.0 && window.zoomBaseSize != null
        ? Size(window.zoomBaseSize!.width * scale, window.zoomBaseSize!.height * scale)
        : fitSize;
    final zoomedWidth = baseSize.width * window.zoom;
    final zoomedHeight = baseSize.height * window.zoom;
    final mediaRect = Rect.fromLTWH(
      windowRect.left + ((windowRect.width - zoomedWidth) / 2) + (window.contentOffset.dx * scale),
      windowRect.top + ((windowRect.height - zoomedHeight) / 2) + (window.contentOffset.dy * scale),
      zoomedWidth,
      zoomedHeight,
    );
    return (mediaRect: mediaRect, visibleRect: mediaRect.intersect(windowRect));
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/video/video_models.dart';

class MediaInspector {
  const MediaInspector({required this.isRunningInWidgetTest});

  final bool isRunningInWidgetTest;

  Future<String> md5ForFile(File file) async {
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<ui.Size?> imageDimensionsForFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    } catch (_) {
      return null;
    }
  }

  Future<int?> videoDurationMsForFile(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration.inMilliseconds;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<VideoProbeResult?> probeVideoFile(File file) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      final result = await videoToolsChannel.invokeMapMethod<String, dynamic>('probeVideo', {'path': file.path});
      if (result == null) {
        return null;
      }

      return VideoProbeResult(
        durationMs: (result['durationMs'] as num?)?.toInt(),
        width: (result['width'] as num?)?.toInt(),
        height: (result['height'] as num?)?.toInt(),
        frameCount: (result['frameCount'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}

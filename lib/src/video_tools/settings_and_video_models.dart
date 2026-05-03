import 'package:flutter/foundation.dart';

@immutable
class SettingsResult {
  const SettingsResult({
    required this.imageLoadLimit,
    required this.shortVideoLoadLimit,
    required this.longVideoLoadLimit,
    required this.knownFolders,
    required this.folderPopularity,
  });

  final int imageLoadLimit;
  final int shortVideoLoadLimit;
  final int longVideoLoadLimit;
  final List<String> knownFolders;
  final Map<String, int> folderPopularity;
}

enum StartupEnvironmentChoice { open, create }

@immutable
class VideoProbeResult {
  const VideoProbeResult({this.durationMs, this.width, this.height, this.frameCount});

  final int? durationMs;
  final int? width;
  final int? height;
  final int? frameCount;

  bool get isSingleFrame => frameCount == 1;
}

@immutable
class VideoConversionResult {
  const VideoConversionResult({
    required this.path,
    required this.filename,
    required this.md5,
    required this.width,
    required this.height,
  });

  final String path;
  final String filename;
  final String md5;
  final double width;
  final double height;
}

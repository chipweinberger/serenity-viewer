part of '../../main.dart';

@immutable
class SerenitySettingsResult {
  const SerenitySettingsResult({
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

class SerenityLoadPlan {
  const SerenityLoadPlan({
    required this.loadedAssetIds,
    required this.loadedImages,
    required this.loadedShortVideos,
    required this.loadedLongVideos,
  });

  final Set<String> loadedAssetIds;
  final int loadedImages;
  final int loadedShortVideos;
  final int loadedLongVideos;
}

@immutable
class RecentlyClosedWindowEntry {
  const RecentlyClosedWindowEntry({
    required this.workspaceId,
    required this.workspaceName,
    required this.window,
    required this.closedAt,
  });

  final String workspaceId;
  final String workspaceName;
  final AssetWindowState window;
  final DateTime closedAt;
}

class WorkspaceMediaCounts {
  const WorkspaceMediaCounts({required this.images, required this.shortVideos, required this.longVideos});

  final int images;
  final int shortVideos;
  final int longVideos;

  int get videos => shortVideos + longVideos;
}

enum _StartupEnvironmentChoice { open, create }

@immutable
class _VideoProbeResult {
  const _VideoProbeResult({this.durationMs, this.width, this.height, this.frameCount});

  final int? durationMs;
  final int? width;
  final int? height;
  final int? frameCount;

  bool get isSingleFrame => frameCount == 1;
}

@immutable
class _VideoConversionResult {
  const _VideoConversionResult({
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

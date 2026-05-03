import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/workspace/workspace_mutations.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

String importedAssetNote({
  required AssetType originalType,
  required AssetType importType,
  required int? videoDurationMs,
  required String sourceFolderName,
}) {
  if (importType == AssetType.video) {
    final videoLabel = videoDurationMs != null && videoDurationMs < 120000 ? 'short video' : 'long video';
    return 'Imported $videoLabel from $sourceFolderName.';
  }

  if (originalType == AssetType.video) {
    return 'Converted single-frame video from $sourceFolderName.';
  }

  return 'Imported image from $sourceFolderName.';
}

Size importedAssetWindowSize({
  required AssetType importType,
  required Size? imageDimensions,
  required Size? videoDimensions,
}) {
  if (importType == AssetType.video) {
    if (videoDimensions == null) {
      return const Size(520, 340);
    }
    return WorkspaceMutations.windowSizeByFittingAspect(
      currentSize: const Size(520, 340),
      contentWidth: videoDimensions.width,
      contentHeight: videoDimensions.height,
    );
  }

  if (imageDimensions == null) {
    return const Size(420, 300);
  }
  return WorkspaceMutations.windowSizeByFittingAspect(
    currentSize: const Size(420, 300),
    contentWidth: imageDimensions.width,
    contentHeight: imageDimensions.height,
  );
}

Offset importedAssetWindowPosition({
  required Offset viewportCenter,
  required int offsetIndex,
  required Size windowSize,
}) {
  return WorkspaceMutations.clampWindowPosition(
    Offset(viewportCenter.dx - 180 + (offsetIndex * 26), viewportCenter.dy - 130 + (offsetIndex * 22)),
    windowSize,
  );
}

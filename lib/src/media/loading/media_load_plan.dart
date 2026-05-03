class MediaLoadPlan {
  const MediaLoadPlan({
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

class WorkspaceMediaCounts {
  const WorkspaceMediaCounts({
    required this.images,
    required this.shortVideos,
    required this.longVideos,
    required this.links,
  });

  final int images;
  final int shortVideos;
  final int longVideos;
  final int links;

  int get videos => shortVideos + longVideos;
  int get total => images + videos + links;
}

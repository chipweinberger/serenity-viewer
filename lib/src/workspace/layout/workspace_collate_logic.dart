part of 'workspace_layout.dart';

Workspace _collateWorkspaceWindows(Workspace workspace, {required Size targetBox}) {
  final targetCenter = workspace.viewportCenter;
  return WorkspaceHelpers.mapWindows(workspace, (window) {
    if (window.asset.type != AssetType.image && window.asset.type != AssetType.video) {
      return window;
    }

    final targetSize = fitSizeForViewportToAspect(targetBox, window.asset.aspectRatio);
    if (targetSize.width <= 0 || targetSize.height <= 0) {
      return window;
    }

    final centeredPosition = _clampWindowPosition(
      Offset(targetCenter.dx - (targetSize.width / 2), targetCenter.dy - (targetSize.height / 2)),
      targetSize,
    );
    return window.copyWith(
      position: centeredPosition,
      size: targetSize,
      zoom: 1,
      clearZoomBase: true,
      clearContentOffset: true,
    );
  });
}

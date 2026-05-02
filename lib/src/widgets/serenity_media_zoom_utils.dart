part of '../../main.dart';

Size _fitSizeForViewportToAspect(Size viewportSize, double aspectRatio) {
  if (viewportSize.width <= 0 || viewportSize.height <= 0 || aspectRatio <= 0) {
    return Size.zero;
  }

  var fittedWidth = viewportSize.width;
  var fittedHeight = fittedWidth / aspectRatio;
  if (fittedHeight > viewportSize.height) {
    fittedHeight = viewportSize.height;
    fittedWidth = fittedHeight * aspectRatio;
  }
  return Size(fittedWidth, fittedHeight);
}

Rect _normalizedVisibleRectForWindow(AssetWindowState window, Size sourceSize) {
  final viewportSize = window.size;
  final fitSize = _fitSizeForViewportToAspect(viewportSize, sourceSize.width / sourceSize.height);
  final baseSize = window.zoom > 1.0 && window.zoomBaseSize != null ? window.zoomBaseSize! : fitSize;
  final zoomedWidth = baseSize.width * window.zoom;
  final zoomedHeight = baseSize.height * window.zoom;
  if (zoomedWidth <= 0 || zoomedHeight <= 0) {
    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  final left = ((viewportSize.width - zoomedWidth) / 2) + window.contentOffset.dx;
  final top = ((viewportSize.height - zoomedHeight) / 2) + window.contentOffset.dy;
  final visibleLeft = math.max(0.0, -left);
  final visibleTop = math.max(0.0, -top);
  final visibleRight = math.min(zoomedWidth, viewportSize.width - left);
  final visibleBottom = math.min(zoomedHeight, viewportSize.height - top);
  final visibleWidth = math.max(0.0, visibleRight - visibleLeft);
  final visibleHeight = math.max(0.0, visibleBottom - visibleTop);
  if (visibleWidth <= 0 || visibleHeight <= 0) {
    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  return Rect.fromLTWH(
    visibleLeft / zoomedWidth,
    visibleTop / zoomedHeight,
    visibleWidth / zoomedWidth,
    visibleHeight / zoomedHeight,
  );
}

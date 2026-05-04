import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/workspace/window/interaction/window_zoom_update.dart';

double assetPreviewScaleForInset(Window window, double inset) {
  if (inset <= 0 || window.size.width <= 0 || window.size.height <= 0) {
    return 1.0;
  }

  final innerWidth = math.max(1.0, window.size.width - (inset * 2));
  final innerHeight = math.max(1.0, window.size.height - (inset * 2));
  return math.min(innerWidth / window.size.width, innerHeight / window.size.height);
}

double assetPreviewScaleForSize(Window window, Size previewSize) {
  if (previewSize.width <= 0 || previewSize.height <= 0 || window.size.width <= 0 || window.size.height <= 0) {
    return 1.0;
  }

  final widthScale = previewSize.width / math.max(1.0, window.size.width);
  final heightScale = previewSize.height / math.max(1.0, window.size.height);
  return math.min(widthScale, heightScale);
}

Window scaleAssetPreviewWindow(Window window, double scale, {Size? size}) {
  if (scale == 1.0 && size == null) {
    return window;
  }

  return window.copyWith(
    size: size,
    zoomBaseWidth: window.zoomBaseWidth == null ? null : window.zoomBaseWidth! * scale,
    zoomBaseHeight: window.zoomBaseHeight == null ? null : window.zoomBaseHeight! * scale,
    contentOffsetDx: window.contentOffset.dx * scale,
    contentOffsetDy: window.contentOffset.dy * scale,
  );
}

WindowZoomUpdate remapWindowZoomUpdateForPreviewScale(WindowZoomUpdate update, double scale) {
  if (scale == 1.0) {
    return update;
  }

  return WindowZoomUpdate(
    zoom: update.zoom,
    zoomBaseSize: update.zoomBaseSize == null
        ? null
        : Size(update.zoomBaseSize!.width / scale, update.zoomBaseSize!.height / scale),
    contentOffset: update.contentOffset == null
        ? null
        : Offset(update.contentOffset!.dx / scale, update.contentOffset!.dy / scale),
    clearZoomBase: update.clearZoomBase,
    clearContentOffset: update.clearContentOffset,
  );
}

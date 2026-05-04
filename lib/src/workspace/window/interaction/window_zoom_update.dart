import 'package:flutter/material.dart';

@immutable
class WindowZoomUpdate {
  const WindowZoomUpdate({
    required this.zoom,
    this.zoomBaseSize,
    this.contentOffset,
    this.clearZoomBase = false,
    this.clearContentOffset = false,
  });

  final double zoom;
  final Size? zoomBaseSize;
  final Offset? contentOffset;
  final bool clearZoomBase;
  final bool clearContentOffset;
}

import 'package:flutter/material.dart';

enum WindowResizeHandle { left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight }

enum CornerResizeHitTestMode { circle, edge }

const double _resizeHitTestEpsilon = 0.5;

WindowResizeHandle? assetWindowResizeHandleForPosition({
  required Size windowSize,
  required Offset localPosition,
  double borderRadius = 16,
  double edgeHitThickness = 8,
  double cornerHitDiameter = 26,
  CornerResizeHitTestMode cornerHitTestMode = CornerResizeHitTestMode.circle,
}) {
  if (windowSize.width <= 0 || windowSize.height <= 0) {
    return null;
  }

  final outerRadiusValue = borderRadius.clamp(0, windowSize.shortestSide / 2).toDouble();
  final outerRadius = Radius.circular(outerRadiusValue);
  final outerRect = Rect.fromLTWH(
    -_resizeHitTestEpsilon,
    -_resizeHitTestEpsilon,
    windowSize.width + (_resizeHitTestEpsilon * 2),
    windowSize.height + (_resizeHitTestEpsilon * 2),
  );
  final outerRRect = RRect.fromRectAndRadius(outerRect, outerRadius);
  final cornerHandle = _cornerResizeHandleForPosition(
    outerRRect: outerRRect,
    localPosition: localPosition,
    cornerHitDiameter: cornerHitDiameter,
  );
  if (cornerHandle != null && cornerHitTestMode == CornerResizeHitTestMode.circle) {
    return cornerHandle;
  }

  if (!outerRRect.contains(localPosition)) {
    return null;
  }

  final clampedEdgeThickness = edgeHitThickness.clamp(0, windowSize.shortestSide / 2).toDouble();
  final innerRect = Rect.fromLTWH(
    clampedEdgeThickness,
    clampedEdgeThickness,
    windowSize.width - (clampedEdgeThickness * 2),
    windowSize.height - (clampedEdgeThickness * 2),
  );
  final innerRadiusValue = (outerRadius.x - clampedEdgeThickness).clamp(0, windowSize.shortestSide / 2).toDouble();
  final innerRRect = innerRect.width > 0 && innerRect.height > 0
      ? RRect.fromRectAndRadius(innerRect, Radius.circular(innerRadiusValue))
      : null;
  final isInEdgeRing = innerRRect == null || !innerRRect.contains(localPosition);
  if (!isInEdgeRing) {
    return null;
  }

  if (cornerHandle != null) {
    return cornerHandle;
  }

  final leftDistance = localPosition.dx;
  final rightDistance = windowSize.width - localPosition.dx;
  final topDistance = localPosition.dy;
  final bottomDistance = windowSize.height - localPosition.dy;
  final nearestDistance = [leftDistance, rightDistance, topDistance, bottomDistance].reduce((a, b) => a < b ? a : b);

  if (nearestDistance == leftDistance) {
    return WindowResizeHandle.left;
  }
  if (nearestDistance == rightDistance) {
    return WindowResizeHandle.right;
  }
  if (nearestDistance == topDistance) {
    return WindowResizeHandle.top;
  }
  return WindowResizeHandle.bottom;
}

WindowResizeHandle? _cornerResizeHandleForPosition({
  required RRect outerRRect,
  required Offset localPosition,
  required double cornerHitDiameter,
}) {
  final circleRadius = cornerHitDiameter / 2;
  final topLeftCenter = _cornerHitCenter(outerRRect.outerRect.topLeft, outerRRect.tlRadiusX, outerRRect.tlRadiusY);
  final topRightCenter = _cornerHitCenter(outerRRect.outerRect.topRight, -outerRRect.trRadiusX, outerRRect.trRadiusY);
  final bottomLeftCenter = _cornerHitCenter(
    outerRRect.outerRect.bottomLeft,
    outerRRect.blRadiusX,
    -outerRRect.blRadiusY,
  );
  final bottomRightCenter = _cornerHitCenter(
    outerRRect.outerRect.bottomRight,
    -outerRRect.brRadiusX,
    -outerRRect.brRadiusY,
  );

  if (_isWithinCircle(localPosition, topLeftCenter, circleRadius)) {
    return WindowResizeHandle.topLeft;
  }
  if (_isWithinCircle(localPosition, topRightCenter, circleRadius)) {
    return WindowResizeHandle.topRight;
  }
  if (_isWithinCircle(localPosition, bottomLeftCenter, circleRadius)) {
    return WindowResizeHandle.bottomLeft;
  }
  if (_isWithinCircle(localPosition, bottomRightCenter, circleRadius)) {
    return WindowResizeHandle.bottomRight;
  }

  return null;
}

bool _isWithinCircle(Offset point, Offset center, double radius) {
  final dx = point.dx - center.dx;
  final dy = point.dy - center.dy;
  return (dx * dx) + (dy * dy) <= radius * radius;
}

Offset _cornerArcCenter(Offset cornerPoint, double radiusDx, double radiusDy) {
  return Offset(cornerPoint.dx + radiusDx, cornerPoint.dy + radiusDy);
}

Offset _cornerHitCenter(Offset cornerPoint, double radiusDx, double radiusDy) {
  final arcCenter = _cornerArcCenter(cornerPoint, radiusDx, radiusDy);
  const diagonalUnit = 0.7071067811865476;
  final xDirection = radiusDx.isNegative ? -1.0 : 1.0;
  final yDirection = radiusDy.isNegative ? -1.0 : 1.0;

  return Offset(
    arcCenter.dx - (radiusDx.abs() * diagonalUnit * xDirection),
    arcCenter.dy - (radiusDy.abs() * diagonalUnit * yDirection),
  );
}

MouseCursor mouseCursorForWindowResizeHandle(WindowResizeHandle? handle) {
  switch (handle) {
    case WindowResizeHandle.left:
    case WindowResizeHandle.right:
      return SystemMouseCursors.resizeLeftRight;
    case WindowResizeHandle.top:
    case WindowResizeHandle.bottom:
      return SystemMouseCursors.resizeUpDown;
    case WindowResizeHandle.topLeft:
    case WindowResizeHandle.bottomRight:
      return SystemMouseCursors.resizeUpLeftDownRight;
    case WindowResizeHandle.topRight:
    case WindowResizeHandle.bottomLeft:
      return SystemMouseCursors.resizeUpRightDownLeft;
    case null:
      return SystemMouseCursors.basic;
  }
}

String nativeCursorKindForWindowResizeHandle(WindowResizeHandle? handle) {
  switch (handle) {
    case WindowResizeHandle.left:
    case WindowResizeHandle.right:
      return 'leftRight';
    case WindowResizeHandle.top:
    case WindowResizeHandle.bottom:
      return 'upDown';
    case WindowResizeHandle.topLeft:
    case WindowResizeHandle.bottomRight:
      return 'diagonalPrimary';
    case WindowResizeHandle.topRight:
    case WindowResizeHandle.bottomLeft:
      return 'diagonalSecondary';
    case null:
      return 'basic';
  }
}

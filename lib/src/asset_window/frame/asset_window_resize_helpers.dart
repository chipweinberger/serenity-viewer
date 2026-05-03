import 'package:flutter/material.dart';

enum AssetWindowResizeHandle { left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight }

AssetWindowResizeHandle? assetWindowResizeHandleForPosition({
  required Size windowSize,
  required Offset localPosition,
  double edgeInset = 8,
  double cornerInset = 26,
}) {
  final isInTopLeftCorner = localPosition.dx <= cornerInset && localPosition.dy <= cornerInset;
  final isInTopRightCorner = localPosition.dx >= windowSize.width - cornerInset && localPosition.dy <= cornerInset;
  final isInBottomLeftCorner = localPosition.dx <= cornerInset && localPosition.dy >= windowSize.height - cornerInset;
  final isInBottomRightCorner =
      localPosition.dx >= windowSize.width - cornerInset && localPosition.dy >= windowSize.height - cornerInset;

  final isLeft = localPosition.dx <= edgeInset;
  final isRight = localPosition.dx >= windowSize.width - edgeInset;
  final isTop = localPosition.dy <= edgeInset;
  final isBottom = localPosition.dy >= windowSize.height - edgeInset;

  if (isInTopLeftCorner) {
    return AssetWindowResizeHandle.topLeft;
  }
  if (isInTopRightCorner) {
    return AssetWindowResizeHandle.topRight;
  }
  if (isInBottomLeftCorner) {
    return AssetWindowResizeHandle.bottomLeft;
  }
  if (isInBottomRightCorner) {
    return AssetWindowResizeHandle.bottomRight;
  }
  if (isLeft) {
    return AssetWindowResizeHandle.left;
  }
  if (isRight) {
    return AssetWindowResizeHandle.right;
  }
  if (isTop) {
    return AssetWindowResizeHandle.top;
  }
  if (isBottom) {
    return AssetWindowResizeHandle.bottom;
  }
  return null;
}

MouseCursor mouseCursorForAssetWindowResizeHandle(AssetWindowResizeHandle? handle) {
  switch (handle) {
    case AssetWindowResizeHandle.left:
    case AssetWindowResizeHandle.right:
      return SystemMouseCursors.resizeLeftRight;
    case AssetWindowResizeHandle.top:
    case AssetWindowResizeHandle.bottom:
      return SystemMouseCursors.resizeUpDown;
    case AssetWindowResizeHandle.topLeft:
    case AssetWindowResizeHandle.bottomRight:
      return SystemMouseCursors.resizeUpLeftDownRight;
    case AssetWindowResizeHandle.topRight:
    case AssetWindowResizeHandle.bottomLeft:
      return SystemMouseCursors.resizeUpRightDownLeft;
    case null:
      return SystemMouseCursors.basic;
  }
}

String nativeCursorKindForAssetWindowResizeHandle(AssetWindowResizeHandle? handle) {
  switch (handle) {
    case AssetWindowResizeHandle.left:
    case AssetWindowResizeHandle.right:
      return 'leftRight';
    case AssetWindowResizeHandle.top:
    case AssetWindowResizeHandle.bottom:
      return 'upDown';
    case AssetWindowResizeHandle.topLeft:
    case AssetWindowResizeHandle.bottomRight:
      return 'diagonalPrimary';
    case AssetWindowResizeHandle.topRight:
    case AssetWindowResizeHandle.bottomLeft:
      return 'diagonalSecondary';
    case null:
      return 'basic';
  }
}

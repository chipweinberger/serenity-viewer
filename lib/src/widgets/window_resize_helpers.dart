part of '../../main.dart';

enum WindowResizeHandle { left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight }

WindowResizeHandle? _windowResizeHandleForPosition({
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
    return WindowResizeHandle.topLeft;
  }
  if (isInTopRightCorner) {
    return WindowResizeHandle.topRight;
  }
  if (isInBottomLeftCorner) {
    return WindowResizeHandle.bottomLeft;
  }
  if (isInBottomRightCorner) {
    return WindowResizeHandle.bottomRight;
  }
  if (isLeft) {
    return WindowResizeHandle.left;
  }
  if (isRight) {
    return WindowResizeHandle.right;
  }
  if (isTop) {
    return WindowResizeHandle.top;
  }
  if (isBottom) {
    return WindowResizeHandle.bottom;
  }
  return null;
}

MouseCursor _mouseCursorForResizeHandle(WindowResizeHandle? handle) {
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

String _nativeCursorKindForResizeHandle(WindowResizeHandle? handle) {
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

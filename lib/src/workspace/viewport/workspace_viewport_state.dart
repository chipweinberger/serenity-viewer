import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';

class WorkspaceViewportState extends ChangeNotifier {
  Size _viewportSize = Size.zero;
  bool _isGestureActive = false;
  Offset _gestureStartCenter = defaultWorkspaceCenter;
  double _gestureStartZoom = 1;
  Offset _gestureStartLocalFocalPoint = Offset.zero;
  Offset _gestureAccumulatedPan = Offset.zero;

  Size get viewportSize => _viewportSize;
  bool get isGestureActive => _isGestureActive;
  Offset get gestureStartCenter => _gestureStartCenter;
  double get gestureStartZoom => _gestureStartZoom;
  Offset get gestureStartLocalFocalPoint => _gestureStartLocalFocalPoint;
  Offset get gestureAccumulatedPan => _gestureAccumulatedPan;

  void setViewportSize(Size value) {
    if (_viewportSize == value) {
      return;
    }

    _viewportSize = value;
    notifyListeners();
  }

  void setGestureInactive() {
    if (!_isGestureActive) {
      return;
    }

    _isGestureActive = false;
    notifyListeners();
  }

  void startGesture({
    required Offset center,
    required double zoom,
    required Offset localFocalPoint,
  }) {
    _isGestureActive = true;
    _gestureStartCenter = center;
    _gestureStartZoom = zoom;
    _gestureStartLocalFocalPoint = localFocalPoint;
    _gestureAccumulatedPan = Offset.zero;
    notifyListeners();
  }

  void accumulateGesturePan(Offset delta) {
    _gestureAccumulatedPan += delta;
    notifyListeners();
  }

  void endGesture() {
    if (!_isGestureActive && _gestureAccumulatedPan == Offset.zero) {
      return;
    }

    _isGestureActive = false;
    _gestureAccumulatedPan = Offset.zero;
    notifyListeners();
  }
}

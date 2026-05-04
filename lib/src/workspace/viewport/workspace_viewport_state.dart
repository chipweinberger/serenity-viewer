import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';

class WorkspaceViewportState extends ChangeNotifier {
  Size _viewportSize = Size.zero;
  Size? _pendingViewportSize;
  bool _isViewportNotificationScheduled = false;
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
    if (_viewportSize == value || _pendingViewportSize == value) {
      return;
    }

    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
        _viewportSize = value;
        notifyListeners();
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        _pendingViewportSize = value;
        _scheduleViewportSizeNotification();
    }
  }

  void _scheduleViewportSizeNotification() {
    if (_isViewportNotificationScheduled) {
      return;
    }

    _isViewportNotificationScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isViewportNotificationScheduled = false;
      final pendingViewportSize = _pendingViewportSize;
      _pendingViewportSize = null;
      if (pendingViewportSize == null || _viewportSize == pendingViewportSize) {
        return;
      }

      _viewportSize = pendingViewportSize;
      notifyListeners();
    });
  }

  void setGestureInactive() {
    if (!_isGestureActive) {
      return;
    }

    _isGestureActive = false;
    notifyListeners();
  }

  void startGesture({required Offset center, required double zoom, required Offset localFocalPoint}) {
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

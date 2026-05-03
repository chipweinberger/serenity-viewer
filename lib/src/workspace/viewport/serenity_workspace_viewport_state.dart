import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/serenity_core.dart';

class SerenityWorkspaceViewportState {
  Size viewportSize = Size.zero;
  bool isGestureActive = false;
  Offset gestureStartCenter = defaultWorkspaceCenter;
  double gestureStartZoom = 1;
  Offset gestureStartLocalFocalPoint = Offset.zero;
  Offset gestureAccumulatedPan = Offset.zero;
}

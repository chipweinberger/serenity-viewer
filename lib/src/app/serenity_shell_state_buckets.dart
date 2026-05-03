part of 'serenity_shell.dart';

class _SerenityWindowInteractionState {
  final Map<String, bool> pausedVideoWindows = {};
  final Map<String, int> previousWindowZOrders = {};
  final Set<String> selectedExposeWindowIds = {};
  final Map<String, _SharedVideoControllerEntry> sharedVideoControllers = {};

  String? optionGestureWindowId;
  String? pinnedHoverWindowId;
  String? flashedWindowId;
  int windowFlashNonce = 0;
  Timer? windowFlashTimer;

  void dispose() {
    windowFlashTimer?.cancel();
    windowFlashTimer = null;
  }
}

class _SerenityThumbnailRefreshState {
  final Map<String, Timer> debounces = {};
  final Set<String> refreshInFlight = {};
  final Set<String> dirtyWorkspaces = {};

  void dispose() {
    for (final timer in debounces.values) {
      timer.cancel();
    }
    debounces.clear();
  }
}

class _SerenityWorkspaceViewTrackingState {
  Timer? timer;
  bool isAppForeground = true;
  String? candidateWorkspaceId;
  bool countedForCurrentContext = false;

  void dispose() {
    timer?.cancel();
    timer = null;
  }
}

class _SerenityWorkspaceViewportState {
  Size viewportSize = Size.zero;
  bool isGestureActive = false;
  Offset gestureStartCenter = defaultWorkspaceCenter;
  double gestureStartZoom = 1;
  Offset gestureStartLocalFocalPoint = Offset.zero;
  Offset gestureAccumulatedPan = Offset.zero;
}

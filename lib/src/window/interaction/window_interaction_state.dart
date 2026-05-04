import 'dart:async';

class WindowInteractionState {
  final Map<String, bool> pausedVideoWindows = {};
  final Map<String, int> previousWindowZOrders = {};
  final Set<String> selectedExposeWindowIds = {};

  String? activeGestureWindowId;
  String? get optionGestureWindowId => activeGestureWindowId;
  set optionGestureWindowId(String? value) => activeGestureWindowId = value;
  String? pinnedHoverWindowId;
  String? flashedWindowId;
  int windowFlashNonce = 0;
  Timer? windowFlashTimer;

  void dispose() {
    windowFlashTimer?.cancel();
    windowFlashTimer = null;
  }
}

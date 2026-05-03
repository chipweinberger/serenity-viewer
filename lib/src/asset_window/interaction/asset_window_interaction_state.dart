import 'dart:async';

class AssetWindowInteractionState {
  final Map<String, bool> pausedVideoWindows = {};
  final Map<String, int> previousWindowZOrders = {};
  final Set<String> selectedExposeWindowIds = {};

  String? activeGestureWindowId;
  String? pinnedHoverWindowId;
  String? flashedWindowId;
  int windowFlashNonce = 0;
  Timer? windowFlashTimer;

  void dispose() {
    windowFlashTimer?.cancel();
    windowFlashTimer = null;
  }
}

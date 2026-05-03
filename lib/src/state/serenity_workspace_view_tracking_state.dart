import 'dart:async';

class SerenityWorkspaceViewTrackingState {
  Timer? timer;
  bool isAppForeground = true;
  String? candidateWorkspaceId;
  bool countedForCurrentContext = false;

  void dispose() {
    timer?.cancel();
    timer = null;
  }
}

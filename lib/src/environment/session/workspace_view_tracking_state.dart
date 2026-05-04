import 'dart:async';

class WorkspaceViewTrackingState {
  Timer? timer;
  bool isAppForeground = true;
  String? candidateWorkspaceId;
  bool countedForCurrentContext = false;

  void dispose() {
    timer?.cancel();
    timer = null;
  }
}

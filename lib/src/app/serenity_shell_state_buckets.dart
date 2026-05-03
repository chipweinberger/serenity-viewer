part of 'serenity_shell.dart';

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

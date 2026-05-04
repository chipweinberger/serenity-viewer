import 'dart:async';

class ThumbnailRefreshState {
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

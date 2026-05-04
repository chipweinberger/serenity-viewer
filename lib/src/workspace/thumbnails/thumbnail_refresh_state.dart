import 'dart:async';

import 'package:flutter/foundation.dart';

class ThumbnailRefreshState extends ChangeNotifier {
  final Map<String, Timer> _debounces = {};
  final Set<String> _refreshInFlight = {};
  final Set<String> _dirtyWorkspaces = {};
  bool _isDisposed = false;

  Set<String> get refreshInFlight => _refreshInFlight;
  Set<String> get dirtyWorkspaces => _dirtyWorkspaces;

  void replaceDebounce(String workspaceId, Timer timer) {
    _debounces[workspaceId]?.cancel();
    _debounces[workspaceId] = timer;
  }

  void clearDebounce(String workspaceId) {
    _debounces.remove(workspaceId)?.cancel();
  }

  bool markWorkspaceDirty(String workspaceId) {
    final changed = _dirtyWorkspaces.add(workspaceId);
    _notifyIfNeeded(changed);
    return changed;
  }

  bool startRefresh(String workspaceId) {
    final changed = _refreshInFlight.add(workspaceId);
    _notifyIfNeeded(changed);
    return changed;
  }

  bool finishRefresh(String workspaceId) {
    final removedDirty = _dirtyWorkspaces.remove(workspaceId);
    final removedRefreshing = _refreshInFlight.remove(workspaceId);
    final changed = removedDirty || removedRefreshing;
    _notifyIfNeeded(changed);
    return changed;
  }

  void _notifyIfNeeded(bool changed) {
    if (!changed || _isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final timer in _debounces.values) {
      timer.cancel();
    }
    _debounces.clear();
    super.dispose();
  }
}

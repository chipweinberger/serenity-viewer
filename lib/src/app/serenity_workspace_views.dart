// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellWorkspaceViews on _SerenityShellState {
  static const Duration _workspaceViewThreshold = Duration(seconds: 30);

  bool get _shouldTrackWorkspaceViewSession {
    return _isAppForeground && _screen == SerenityScreen.workspace && _activeWorkspaceOrNull != null;
  }

  String? _currentWorkspaceViewCandidateId() {
    if (!_shouldTrackWorkspaceViewSession) {
      return null;
    }
    return _activeWorkspaceOrNull?.id;
  }

  void _handleAppLifecycleStateChanged(AppLifecycleState state) {
    final nextForeground = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };
    if (_isAppForeground == nextForeground) {
      return;
    }

    _isAppForeground = nextForeground;
    _refreshWorkspaceViewTracking();
  }

  void _refreshWorkspaceViewTracking() {
    final candidateId = _currentWorkspaceViewCandidateId();
    if (candidateId == null) {
      _cancelWorkspaceViewTracking();
      return;
    }

    if (_workspaceViewCandidateId != candidateId) {
      _workspaceViewTimer?.cancel();
      _workspaceViewTimer = null;
      _workspaceViewCandidateId = candidateId;
      _workspaceViewCountedForCurrentContext = false;
    }

    if (_workspaceViewCountedForCurrentContext || _workspaceViewTimer != null) {
      return;
    }

    _workspaceViewTimer = Timer(_workspaceViewThreshold, () {
      _workspaceViewTimer = null;
      if (!mounted) {
        return;
      }

      final currentCandidateId = _currentWorkspaceViewCandidateId();
      if (currentCandidateId != candidateId || _workspaceViewCountedForCurrentContext) {
        return;
      }

      _workspaceViewCountedForCurrentContext = true;
      _incrementWorkspaceViews(candidateId);
    });
  }

  void _cancelWorkspaceViewTracking() {
    _workspaceViewTimer?.cancel();
    _workspaceViewTimer = null;
    _workspaceViewCandidateId = null;
    _workspaceViewCountedForCurrentContext = false;
  }

  void _incrementWorkspaceViews(String workspaceId) {
    final session = _session;
    if (session == null) {
      return;
    }

    final now = DateTime.now();

    _updateSession(
      session.copyWith(
        workspaces: session.workspaces
            .map((entry) => entry.id == workspaceId ? entry.copyWith(views: entry.views + 1, lastViewedAt: now) : entry)
            .toList(),
      ),
    );
  }
}

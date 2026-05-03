// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/serenity_shell.dart';

extension _SerenityShellWorkspaceViews on _SerenityShellState {
  static const Duration _workspaceViewThreshold = Duration(seconds: 30);

  bool get _shouldTrackWorkspaceViewSession {
    return _workspaceViewTrackingState.isAppForeground &&
        _uiState.screen == SerenityScreen.workspace &&
        _activeWorkspaceOrNull != null;
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
    if (_workspaceViewTrackingState.isAppForeground == nextForeground) {
      return;
    }

    _workspaceViewTrackingState.isAppForeground = nextForeground;
    _refreshWorkspaceViewTracking();
  }

  void _refreshWorkspaceViewTracking() {
    final candidateId = _currentWorkspaceViewCandidateId();
    if (candidateId == null) {
      _cancelWorkspaceViewTracking();
      return;
    }

    if (_workspaceViewTrackingState.candidateWorkspaceId != candidateId) {
      _workspaceViewTrackingState.timer?.cancel();
      _workspaceViewTrackingState.timer = null;
      _workspaceViewTrackingState.candidateWorkspaceId = candidateId;
      _workspaceViewTrackingState.countedForCurrentContext = false;
    }

    if (_workspaceViewTrackingState.countedForCurrentContext || _workspaceViewTrackingState.timer != null) {
      return;
    }

    _workspaceViewTrackingState.timer = Timer(_workspaceViewThreshold, () {
      _workspaceViewTrackingState.timer = null;
      if (!mounted) {
        return;
      }

      final currentCandidateId = _currentWorkspaceViewCandidateId();
      if (currentCandidateId != candidateId || _workspaceViewTrackingState.countedForCurrentContext) {
        return;
      }

      _workspaceViewTrackingState.countedForCurrentContext = true;
      _incrementWorkspaceViews(candidateId);
    });
  }

  void _cancelWorkspaceViewTracking() {
    _workspaceViewTrackingState.timer?.cancel();
    _workspaceViewTrackingState.timer = null;
    _workspaceViewTrackingState.candidateWorkspaceId = null;
    _workspaceViewTrackingState.countedForCurrentContext = false;
  }

  void _incrementWorkspaceViews(String workspaceId) {
    final session = _persistenceState.session;
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

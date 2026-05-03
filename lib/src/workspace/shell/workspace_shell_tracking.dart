part of 'workspace_shell_controller.dart';

class WorkspaceShellTrackingApi {
  WorkspaceShellTrackingApi._(this._controller);

  static const Duration _workspaceViewThreshold = Duration(seconds: 30);

  final WorkspaceShellController _controller;

  bool get _shouldTrackWorkspaceViewEnvironment {
    return _controller.workspaceViewTrackingState.isAppForeground &&
        _controller.chromeState.screen == SerenityScreen.workspace &&
        _controller.activeWorkspace() != null;
  }

  String? _currentWorkspaceViewCandidateId() {
    if (!_shouldTrackWorkspaceViewEnvironment) {
      return null;
    }

    return _controller.activeWorkspace()?.id;
  }

  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    final nextForeground = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };
    if (_controller.workspaceViewTrackingState.isAppForeground == nextForeground) {
      return;
    }

    _controller.workspaceViewTrackingState.isAppForeground = nextForeground;
    refresh();
  }

  void refresh() {
    final candidateId = _currentWorkspaceViewCandidateId();
    if (candidateId == null) {
      cancel();
      return;
    }

    if (_controller.workspaceViewTrackingState.candidateWorkspaceId != candidateId) {
      _controller.workspaceViewTrackingState.timer?.cancel();
      _controller.workspaceViewTrackingState.timer = null;
      _controller.workspaceViewTrackingState.candidateWorkspaceId = candidateId;
      _controller.workspaceViewTrackingState.countedForCurrentContext = false;
    }

    if (_controller.workspaceViewTrackingState.countedForCurrentContext ||
        _controller.workspaceViewTrackingState.timer != null) {
      return;
    }

    _controller.workspaceViewTrackingState.timer = Timer(_workspaceViewThreshold, () {
      _controller.workspaceViewTrackingState.timer = null;
      if (!_controller.mounted()) {
        return;
      }

      final currentCandidateId = _currentWorkspaceViewCandidateId();
      if (currentCandidateId != candidateId || _controller.workspaceViewTrackingState.countedForCurrentContext) {
        return;
      }

      _controller.workspaceViewTrackingState.countedForCurrentContext = true;
      _incrementWorkspaceViews(candidateId);
    });
  }

  void cancel() {
    _controller.workspaceViewTrackingState.timer?.cancel();
    _controller.workspaceViewTrackingState.timer = null;
    _controller.workspaceViewTrackingState.candidateWorkspaceId = null;
    _controller.workspaceViewTrackingState.countedForCurrentContext = false;
  }

  void _incrementWorkspaceViews(String workspaceId) {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final now = DateTime.now();
    _controller.updateEnvironment(
      environment.copyWith(
        workspaces: environment.workspaces
            .map((entry) => entry.id == workspaceId ? entry.copyWith(views: entry.views + 1, lastViewedAt: now) : entry)
            .toList(),
      ),
    );
  }
}

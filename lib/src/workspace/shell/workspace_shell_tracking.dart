import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/session/workspace_view_tracking_state.dart';

class WorkspaceShellTrackingDependencies {
  const WorkspaceShellTrackingDependencies({
    required this.persistenceState,
    required this.chromeState,
    required this.workspaceViewTrackingState,
    required this.mounted,
    required this.activeWorkspace,
    required this.updateEnvironment,
  });

  final AppEnvironmentState persistenceState;
  final ChromeState chromeState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final bool Function() mounted;
  final Workspace? Function() activeWorkspace;
  final ValueChanged<Environment> updateEnvironment;
}

class WorkspaceShellTrackingApi {
  WorkspaceShellTrackingApi(this._dependencies);

  static const Duration _workspaceViewThreshold = Duration(seconds: 30);

  final WorkspaceShellTrackingDependencies _dependencies;

  bool get _shouldTrackWorkspaceViewEnvironment {
    return _dependencies.workspaceViewTrackingState.isAppForeground &&
        _dependencies.chromeState.screen == SerenityScreen.workspace &&
        _dependencies.activeWorkspace() != null;
  }

  String? _currentWorkspaceViewCandidateId() {
    if (!_shouldTrackWorkspaceViewEnvironment) {
      return null;
    }

    return _dependencies.activeWorkspace()?.id;
  }

  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    final nextForeground = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };
    if (_dependencies.workspaceViewTrackingState.isAppForeground == nextForeground) {
      return;
    }

    _dependencies.workspaceViewTrackingState.isAppForeground = nextForeground;
    refresh();
  }

  void refresh() {
    final candidateId = _currentWorkspaceViewCandidateId();
    if (candidateId == null) {
      cancel();
      return;
    }

    if (_dependencies.workspaceViewTrackingState.candidateWorkspaceId != candidateId) {
      _dependencies.workspaceViewTrackingState.timer?.cancel();
      _dependencies.workspaceViewTrackingState.timer = null;
      _dependencies.workspaceViewTrackingState.candidateWorkspaceId = candidateId;
      _dependencies.workspaceViewTrackingState.countedForCurrentContext = false;
    }

    if (_dependencies.workspaceViewTrackingState.countedForCurrentContext ||
        _dependencies.workspaceViewTrackingState.timer != null) {
      return;
    }

    _dependencies.workspaceViewTrackingState.timer = Timer(_workspaceViewThreshold, () {
      _dependencies.workspaceViewTrackingState.timer = null;
      if (!_dependencies.mounted()) {
        return;
      }

      final currentCandidateId = _currentWorkspaceViewCandidateId();
      if (currentCandidateId != candidateId || _dependencies.workspaceViewTrackingState.countedForCurrentContext) {
        return;
      }

      _dependencies.workspaceViewTrackingState.countedForCurrentContext = true;
      _incrementWorkspaceViews(candidateId);
    });
  }

  void cancel() {
    _dependencies.workspaceViewTrackingState.timer?.cancel();
    _dependencies.workspaceViewTrackingState.timer = null;
    _dependencies.workspaceViewTrackingState.candidateWorkspaceId = null;
    _dependencies.workspaceViewTrackingState.countedForCurrentContext = false;
  }

  void _incrementWorkspaceViews(String workspaceId) {
    final environment = _dependencies.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final now = DateTime.now();
    _dependencies.updateEnvironment(
      environment.copyWith(
        workspaces: environment.workspaces
            .map((entry) => entry.id == workspaceId ? entry.copyWith(views: entry.views + 1, lastViewedAt: now) : entry)
            .toList(),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';

class ThumbnailController {
  ThumbnailController({
    required this.state,
    required this.refresher,
    required this.activeScreen,
    required this.activeWorkspaceId,
    required this.viewportSize,
    required this.commitStateChange,
    required this.isMounted,
  });

  final ThumbnailRefreshState state;
  final ThumbnailRefresher refresher;
  final SerenityScreen Function() activeScreen;
  final String? Function() activeWorkspaceId;
  final Size Function() viewportSize;
  final void Function(VoidCallback update) commitStateChange;
  final bool Function() isMounted;

  Set<String> get refreshingWorkspaceIds => state.refreshInFlight;

  void markWorkspaceDirty(String workspaceId) {
    state.dirtyWorkspaces.add(workspaceId);
  }

  void queueWorkspaceRefresh(String workspaceId, {Duration delay = const Duration(milliseconds: 300)}) {
    state.debounces[workspaceId]?.cancel();
    state.debounces[workspaceId] = Timer(delay, () {
      markWorkspaceDirty(workspaceId);
      state.debounces.remove(workspaceId);
      unawaited(refreshActiveWorkspaceIfNeeded());
    });
  }

  Future<void> refreshActiveWorkspaceIfNeeded() async {
    if (activeScreen() != SerenityScreen.workspace) {
      return;
    }

    final workspaceId = activeWorkspaceId();
    if (workspaceId == null || !state.dirtyWorkspaces.contains(workspaceId)) {
      return;
    }

    final currentViewportSize = viewportSize();
    if (currentViewportSize.width <= 0 || currentViewportSize.height <= 0) {
      return;
    }

    if (state.refreshInFlight.contains(workspaceId)) {
      return;
    }

    _commitRefreshState(() {
      state.refreshInFlight.add(workspaceId);
    });

    try {
      await refresher.refreshWorkspace(workspaceId, viewportSize: currentViewportSize);
    } finally {
      _commitRefreshState(() {
        state.dirtyWorkspaces.remove(workspaceId);
        state.refreshInFlight.remove(workspaceId);
      });
    }
  }

  void dispose() {
    state.dispose();
  }

  void _commitRefreshState(VoidCallback update) {
    if (!isMounted()) {
      update();
      return;
    }

    commitStateChange(update);
  }
}

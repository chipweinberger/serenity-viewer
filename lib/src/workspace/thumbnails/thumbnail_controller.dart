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
  });

  final ThumbnailRefreshState state;
  final ThumbnailRefresher refresher;
  final SerenityScreen Function() activeScreen;
  final String? Function() activeWorkspaceId;
  final Size Function() viewportSize;

  Set<String> get refreshingWorkspaceIds => state.refreshInFlight;

  void markWorkspaceDirty(String workspaceId) {
    state.markWorkspaceDirty(workspaceId);
  }

  void queueWorkspaceRefresh(String workspaceId, {Duration delay = const Duration(milliseconds: 300)}) {
    state.replaceDebounce(
      workspaceId,
      Timer(delay, () {
        markWorkspaceDirty(workspaceId);
        state.clearDebounce(workspaceId);
        unawaited(refreshActiveWorkspaceIfNeeded());
      }),
    );
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

    state.startRefresh(workspaceId);

    try {
      await refresher.refreshWorkspace(workspaceId, viewportSize: currentViewportSize);
    } finally {
      state.finishRefresh(workspaceId);
    }
  }

  void dispose() {
    state.dispose();
  }
}

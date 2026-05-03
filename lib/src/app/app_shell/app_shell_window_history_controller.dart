import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';

class AppShellWindowHistoryController {
  AppShellWindowHistoryController({
    required this.environment,
    required this.workspaces,
    required this.activeWorkspace,
    required this.recentlyClosedWindows,
    required this.workspaceController,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.commitStateChange,
    required this.showMessage,
    required this.showWorkspaceScreen,
    required this.screen,
    required this.maxRecentlyClosedWindows,
  });

  final Environment? Function() environment;
  final List<Workspace> Function() workspaces;
  final Workspace? Function() activeWorkspace;
  final List<RecentlyClosedWindowEntry> recentlyClosedWindows;
  final WorkspaceController workspaceController;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final StateSetter commitStateChange;
  final ValueChanged<String> showMessage;
  final void Function({
    WorkspaceLayoutMode workspaceLayoutMode,
    bool resetEditMode,
    bool clearExposeSelection,
    bool refreshWorkspaceTracking,
  })
  showWorkspaceScreen;
  final SerenityScreen Function() screen;
  final int maxRecentlyClosedWindows;

  Window? focusedWindowOrNull() {
    return workspaceController.windows.focusedOrNull(activeWorkspace());
  }

  void closeWindow(String workspaceId, String windowId) {
    final workspaceMatches = workspaces().where((entry) => entry.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final windowMatches = workspace.windows.where((entry) => entry.asset.id == windowId);
    final window = windowMatches.isEmpty ? null : windowMatches.first;
    if (window == null) {
      return;
    }

    commitStateChange(() {
      workspaceController.windows.rememberClosedWindow(
        recentlyClosedWindows,
        maxRecentlyClosedWindows: maxRecentlyClosedWindows,
        workspace: workspace,
        window: window,
      );
      workspaceController.playback.clearRuntimeState(windowId);
      workspaceController.windows.clearRuntimeState(windowId);
    });

    replaceWorkspace(
      workspace.copyWith(windows: workspace.windows.where((entry) => entry.asset.id != windowId).toList()),
    );
  }

  void removeWindow(String workspaceId, String windowId) {
    workspaceController.expose.removeWindowSelection(windowId);
    closeWindow(workspaceId, windowId);
  }

  void restoreRecentlyClosedWindow([RecentlyClosedWindowEntry? entry]) {
    final targetEntry = entry ?? (recentlyClosedWindows.isEmpty ? null : recentlyClosedWindows.first);
    final currentEnvironment = environment();
    if (targetEntry == null || currentEnvironment == null) {
      showMessage('There are no recently closed windows to restore.');
      return;
    }

    final workspaceMatches = workspaces().where((workspace) => workspace.id == targetEntry.workspaceId);
    final workspace = workspaceMatches.isEmpty ? null : workspaceMatches.first;
    if (workspace == null) {
      commitStateChange(() {
        recentlyClosedWindows.remove(targetEntry);
      });
      showMessage('The original workspace for that window is no longer available.');
      return;
    }

    final nextZ = workspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    final restoredWindow = targetEntry.window.copyWith(zIndex: nextZ + 1);

    commitStateChange(() {
      recentlyClosedWindows.remove(targetEntry);
    });

    updateEnvironment(
      currentEnvironment.copyWith(
        activeWorkspaceId: workspace.id,
        workspaces: currentEnvironment.workspaces
            .map(
              (entry) => entry.id == workspace.id
                  ? entry.copyWith(windows: [...workspace.windows, restoredWindow], isOpen: true)
                  : entry,
            )
            .toList(),
      ),
    );

    if (screen() == SerenityScreen.library) {
      showWorkspaceScreen(resetEditMode: false, clearExposeSelection: false, refreshWorkspaceTracking: false);
    }
  }
}

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_stacking_operations.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';

import 'workspace_controller.dart';

const Size workspaceCollateTargetBox = Size(700, 700);

class WorkspaceWindowControllerState {
  WorkspaceWindowControllerState({
    required this.chromeState,
    required this.commitInteractionState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  });

  final ChromeState chromeState;
  final SerenityWorkspaceCommit commitInteractionState;
  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;

  Window? focusedWindowOrNull(Workspace? workspace) {
    if (workspace == null || workspace.windows.isEmpty) {
      return null;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sortedWindows.last;
  }

  void focusWindow(Workspace workspace, String windowId) {
    final result = WorkspaceStackingOperations.focusWindow(workspace, windowId);
    if (identical(result.workspace, workspace)) {
      return;
    }

    if (result.previousZOrder != null) {
      windowInteractionState.previousWindowZOrders[windowId] = result.previousZOrder!;
    }
    replaceWorkspace(result.workspace, queueThumbnail: true);
  }

  void restorePreviousWindowZOrder(Workspace workspace, String windowId) {
    final previousZ = windowInteractionState.previousWindowZOrders.remove(windowId);
    if (previousZ == null) {
      return;
    }

    replaceWorkspace(
      WorkspaceStackingOperations.restorePreviousWindowZOrder(workspace, windowId, previousZ),
      queueThumbnail: true,
    );
  }

  void moveWindow(Workspace workspace, String windowId, Offset delta) {
    replaceWorkspace(WorkspaceLayout.moveWindow(workspace, windowId, delta), queueThumbnail: true);
  }

  void resizeWindow(Workspace workspace, String windowId, AssetWindowResizeHandle handle, Offset delta) {
    replaceWorkspace(WorkspaceLayout.resizeWindow(workspace, windowId, handle, delta), queueThumbnail: true);
  }

  void transformWindowFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
    replaceWorkspace(
      WorkspaceLayout.transformWindowFromTrackpad(workspace, windowId, scaleDelta),
      queueThumbnail: true,
    );
  }

  void fitWindowToContent(Workspace? workspace, String windowId) {
    if (workspace == null || workspace.windows.every((window) => window.asset.id != windowId)) {
      return;
    }

    replaceWorkspace(WorkspaceLayout.fitWindowToContent(workspace, windowId), queueThumbnail: true);
  }

  void handleOptionGestureHover(
    PointerHoverEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    final targetWindowId = windowInteractionState.activeGestureWindowId;
    if (chromeState.screen != SerenityScreen.workspace ||
        chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose ||
        isCommandPressedForContentGesture ||
        !isOptionPressedForWindowGesture ||
        targetWindowId == null ||
        event.delta == Offset.zero) {
      return;
    }

    moveWindow(workspace, targetWindowId, event.delta / workspace.viewportZoom);
  }

  void flashWindow(String windowId, {required bool mounted}) {
    windowInteractionState.windowFlashTimer?.cancel();
    commitInteractionState(() {
      windowInteractionState.flashedWindowId = windowId;
      windowInteractionState.windowFlashNonce += 1;
    });
    windowInteractionState.windowFlashTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || windowInteractionState.flashedWindowId != windowId) {
        return;
      }
      commitInteractionState(() {
        windowInteractionState.flashedWindowId = null;
      });
    });
  }

  void setWindowZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    replaceWorkspace(WorkspaceLayout.setWindowZoom(workspace, windowId, update), queueThumbnail: true);
  }

  void setWindowIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    if (workspace == null || intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return;
    }

    if (workspace.windows.where((window) => window.asset.id == windowId).isEmpty) {
      return;
    }

    replaceWorkspace(WorkspaceLayout.setWindowIntrinsicSize(workspace, windowId, intrinsicSize), queueThumbnail: true);
  }

  void clearWindowRuntimeState(String windowId) {
    windowInteractionState.previousWindowZOrders.remove(windowId);
  }

  void rememberClosedWindow(
    List<RecentlyClosedWindowEntry> recentlyClosedWindows, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    recentlyClosedWindows.insert(
      0,
      RecentlyClosedWindowEntry(
        workspaceId: workspace.id,
        workspaceName: workspace.name,
        window: window,
        closedAt: DateTime.now(),
      ),
    );

    if (recentlyClosedWindows.length > maxRecentlyClosedWindows) {
      recentlyClosedWindows.removeRange(maxRecentlyClosedWindows, recentlyClosedWindows.length);
    }
  }

  bool canCollateWorkspaceWindows(Workspace? workspace) {
    return workspace != null &&
        chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose &&
        workspace.windows.any((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video);
  }

  int collatableWindowCount(Workspace workspace) {
    return workspace.windows
        .where((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video)
        .length;
  }

  void collateWorkspaceWindows(Workspace workspace) {
    replaceWorkspace(
      WorkspaceLayout.collateWorkspaceWindows(workspace, targetBox: workspaceCollateTargetBox),
      queueThumbnail: true,
    );
  }
}

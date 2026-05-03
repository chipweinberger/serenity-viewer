import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_environment_operations.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_playback_operations.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_stacking_operations.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

part 'workspace_collate.dart';
part 'workspace_zoom_to_fit.dart';

typedef SerenityWorkspaceCommit = void Function(VoidCallback update);
typedef SerenityWorkspaceReplace = void Function(Workspace workspace, {bool queueThumbnail});
typedef SerenityWorkspaceViewportSetter =
    void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail});

class WorkspaceController {
  WorkspaceController({
    required this.chromeState,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.commitInteractionState,
    required this.replaceWorkspace,
    required this.setWorkspaceViewport,
    required this.refreshActiveWorkspaceThumbnail,
  });

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;

  Window? focusedWindowOrNull(Workspace? workspace) {
    if (workspace == null || workspace.windows.isEmpty) {
      return null;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sortedWindows.last;
  }

  void setOptionGestureWindowId(String? windowId) {
    if (windowInteractionState.optionGestureWindowId == windowId) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.optionGestureWindowId = windowId;
    });
  }

  void setPinnedHoverWindow(String? windowId) {
    if (windowInteractionState.pinnedHoverWindowId == windowId) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.pinnedHoverWindowId = windowId;
    });
  }

  void clearPinnedHoverWindow() {
    setPinnedHoverWindow(null);
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

  void toggleExposeWindowSelected(String windowId) {
    commitInteractionState(() {
      if (windowInteractionState.selectedExposeWindowIds.contains(windowId)) {
        windowInteractionState.selectedExposeWindowIds.remove(windowId);
      } else {
        windowInteractionState.selectedExposeWindowIds.add(windowId);
      }
    });
  }

  void clearExposeSelection() {
    if (windowInteractionState.selectedExposeWindowIds.isEmpty) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.selectedExposeWindowIds.clear();
    });
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
    final targetWindowId = windowInteractionState.optionGestureWindowId;
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

  void handleWorkspacePanZoomStart(
    PointerPanZoomStartEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    if (chromeState.screen != SerenityScreen.workspace ||
        chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose ||
        windowInteractionState.pinnedHoverWindowId != null ||
        isCommandPressedForContentGesture ||
        isOptionPressedForWindowGesture) {
      workspaceViewportState.isGestureActive = false;
      return;
    }

    workspaceViewportState.isGestureActive = true;
    workspaceViewportState.gestureStartCenter = workspace.viewportCenter;
    workspaceViewportState.gestureStartZoom = workspace.viewportZoom;
    workspaceViewportState.gestureStartLocalFocalPoint = event.localPosition;
    workspaceViewportState.gestureAccumulatedPan = Offset.zero;
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    if (!workspaceViewportState.isGestureActive) {
      return;
    }

    workspaceViewportState.gestureAccumulatedPan += event.panDelta;
    final nextZoom = WorkspaceLayout.clampWorkspaceZoom(
      workspaceViewportState.gestureStartZoom * math.pow(event.scale, 1.15).toDouble(),
    );
    final viewportCenter = viewportSize.center(Offset.zero);
    final anchorWorldPoint =
        workspaceViewportState.gestureStartCenter +
        ((workspaceViewportState.gestureStartLocalFocalPoint - viewportCenter) /
            workspaceViewportState.gestureStartZoom);
    final nextAnchorLocalPoint =
        workspaceViewportState.gestureStartLocalFocalPoint + workspaceViewportState.gestureAccumulatedPan;
    final nextCenter = WorkspaceLayout.clampWorkspaceCenter(
      center: anchorWorldPoint - ((nextAnchorLocalPoint - viewportCenter) / nextZoom),
      zoom: nextZoom,
      viewportSize: viewportSize,
    );
    setWorkspaceViewport(workspaceId: workspace.id, center: nextCenter, zoom: nextZoom, queueThumbnail: false);
  }

  Future<void> handleWorkspacePanZoomEnd() async {
    workspaceViewportState.isGestureActive = false;
    workspaceViewportState.gestureAccumulatedPan = Offset.zero;
    await refreshActiveWorkspaceThumbnail();
  }

  void setWindowZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    replaceWorkspace(WorkspaceLayout.setWindowZoom(workspace, windowId, update), queueThumbnail: true);
  }

  void setVideoPosition(Workspace? workspace, String windowId, int positionMs) {
    if (workspace == null) {
      return;
    }

    final currentWindow = workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
    if (currentWindow == null || currentWindow.videoPositionMs == positionMs) {
      return;
    }

    replaceWorkspace(
      WorkspacePlaybackOperations.setVideoPosition(workspace, windowId, positionMs),
      queueThumbnail: false,
    );
  }

  void cycleVideoPlaybackSpeed(Workspace? workspace, String windowId) {
    if (workspace == null ||
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isEmpty) {
      return;
    }

    replaceWorkspace(WorkspacePlaybackOperations.cycleVideoPlaybackSpeed(workspace, windowId), queueThumbnail: false);
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

  bool isVideoWindowPaused(String windowId) {
    return windowInteractionState.pausedVideoWindows[windowId] ?? true;
  }

  void toggleVideoPlayback(Workspace? workspace, String windowId) {
    if (workspace == null ||
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isEmpty) {
      return;
    }

    commitInteractionState(() {
      windowInteractionState.pausedVideoWindows[windowId] =
          !(windowInteractionState.pausedVideoWindows[windowId] ?? true);
    });
  }

  void pauseAllVideos(Environment? environment) {
    if (environment == null) {
      return;
    }

    commitInteractionState(() {
      for (final workspace in environment.workspaces) {
        for (final window in workspace.windows) {
          if (window.asset.type == AssetType.video) {
            windowInteractionState.pausedVideoWindows[window.asset.id] = true;
          }
        }
      }
    });
  }

  void removeWindowSelection(String windowId) {
    windowInteractionState.selectedExposeWindowIds.remove(windowId);
  }

  void clearWindowRuntimeState(String windowId) {
    windowInteractionState.previousWindowZOrders.remove(windowId);
    windowInteractionState.pausedVideoWindows.remove(windowId);
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

  void toggleWorkspaceOpen(Environment environment, String workspaceId, void Function(Environment) updateEnvironment) {
    updateEnvironment(WorkspaceEnvironmentOperations.toggleWorkspaceOpen(environment, workspaceId));
  }

  void reorderOpenWorkspace(
    Environment? environment,
    List<Workspace> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required void Function(Environment) updateEnvironment,
  }) {
    if (environment == null || sourceWorkspaceId == targetWorkspaceId) {
      return;
    }

    updateEnvironment(
      environment.copyWith(
        workspaces: WorkspaceEnvironmentOperations.reorderOpenWorkspaces(
          workspaces,
          sourceWorkspaceId: sourceWorkspaceId,
          targetWorkspaceId: targetWorkspaceId,
        ),
      ),
    );
  }

  bool canMoveSelectedWindowsToWorkspace({
    required Environment? environment,
    required Workspace? sourceWorkspace,
    required String destinationWorkspaceId,
  }) {
    return environment != null &&
        sourceWorkspace != null &&
        windowInteractionState.selectedExposeWindowIds.isNotEmpty &&
        destinationWorkspaceId != sourceWorkspace.id;
  }

  int selectedExposeWindowCount(Workspace workspace) {
    return workspace.windows
        .where((window) => windowInteractionState.selectedExposeWindowIds.contains(window.asset.id))
        .length;
  }

  void moveSelectedExposeWindowsToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
  }) {
    updateEnvironment(
      WorkspaceEnvironmentOperations.moveSelectedWindowsToWorkspace(
        environment,
        sourceWorkspaceId: sourceWorkspace.id,
        destinationWorkspaceId: destinationWorkspace.id,
        selectedWindowIds: windowInteractionState.selectedExposeWindowIds,
      ),
    );
    queueThumbnailRefresh(sourceWorkspace.id, delay: Duration.zero);
    queueThumbnailRefresh(destinationWorkspace.id, delay: Duration.zero);
    clearExposeSelection();
  }
}

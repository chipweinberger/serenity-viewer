import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/workspace_mutations.dart';
import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/workspace/windows/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/workspace/windows/window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/workspace_state.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_resize_helpers.dart';

typedef SerenityWorkspaceStateCommit = void Function(VoidCallback update);
typedef SerenityWorkspaceReplace = void Function(WorkspaceState workspace, {bool queueThumbnail});
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

  static const Size collateTargetBox = Size(700, 700);

  final ChromeState chromeState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceStateCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;

  WorkspaceWindowState? focusedWindowOrNull(WorkspaceState? workspace) {
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

  void focusWindow(WorkspaceState workspace, String windowId) {
    final result = WorkspaceMutations.focusWindow(workspace, windowId);
    if (identical(result.workspace, workspace)) {
      return;
    }

    if (result.previousZOrder != null) {
      windowInteractionState.previousWindowZOrders[windowId] = result.previousZOrder!;
    }
    replaceWorkspace(result.workspace, queueThumbnail: true);
  }

  void restorePreviousWindowZOrder(WorkspaceState workspace, String windowId) {
    final previousZ = windowInteractionState.previousWindowZOrders.remove(windowId);
    if (previousZ == null) {
      return;
    }

    replaceWorkspace(
      WorkspaceMutations.restorePreviousWindowZOrder(workspace, windowId, previousZ),
      queueThumbnail: true,
    );
  }

  void moveWindow(WorkspaceState workspace, String windowId, Offset delta) {
    replaceWorkspace(WorkspaceMutations.moveWindow(workspace, windowId, delta), queueThumbnail: true);
  }

  bool canCollateWorkspaceWindows(WorkspaceState? workspace) {
    return workspace != null &&
        chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose &&
        workspace.windows.any((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video);
  }

  int collatableWindowCount(WorkspaceState workspace) {
    return workspace.windows
        .where((window) => window.asset.type == AssetType.image || window.asset.type == AssetType.video)
        .length;
  }

  void collateWorkspaceWindows(WorkspaceState workspace) {
    replaceWorkspace(
      WorkspaceMutations.collateWorkspaceWindows(workspace, targetBox: collateTargetBox),
      queueThumbnail: true,
    );
  }

  void resizeWindow(WorkspaceState workspace, String windowId, WindowResizeHandle handle, Offset delta) {
    replaceWorkspace(WorkspaceMutations.resizeWindow(workspace, windowId, handle, delta), queueThumbnail: true);
  }

  void transformWindowFromTrackpad(WorkspaceState workspace, String windowId, double scaleDelta) {
    replaceWorkspace(
      WorkspaceMutations.transformWindowFromTrackpad(workspace, windowId, scaleDelta),
      queueThumbnail: true,
    );
  }

  void fitWindowToContent(WorkspaceState? workspace, String windowId) {
    if (workspace == null || workspace.windows.every((window) => window.asset.id != windowId)) {
      return;
    }

    replaceWorkspace(WorkspaceMutations.fitWindowToContent(workspace, windowId), queueThumbnail: true);
  }

  void fitWorkspaceViewportToContent(WorkspaceState? workspace) {
    if (workspace == null) {
      return;
    }

    if (workspaceViewportState.viewportSize.width <= 0 ||
        workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      setWorkspaceViewport(workspaceId: workspace.id, center: defaultWorkspaceCenter, zoom: 1, queueThumbnail: true);
      return;
    }

    replaceWorkspace(
      WorkspaceMutations.fitWorkspaceViewportToContent(workspace, workspaceViewportState.viewportSize),
      queueThumbnail: true,
    );
  }

  void handleOptionGestureHover(
    PointerHoverEvent event,
    WorkspaceState workspace, {
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
    WorkspaceState workspace, {
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

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, WorkspaceState workspace, Size viewportSize) {
    if (!workspaceViewportState.isGestureActive) {
      return;
    }

    workspaceViewportState.gestureAccumulatedPan += event.panDelta;
    final nextZoom = WorkspaceMutations.clampWorkspaceZoom(
      workspaceViewportState.gestureStartZoom * math.pow(event.scale, 1.15).toDouble(),
    );
    final viewportCenter = viewportSize.center(Offset.zero);
    final anchorWorldPoint =
        workspaceViewportState.gestureStartCenter +
        ((workspaceViewportState.gestureStartLocalFocalPoint - viewportCenter) /
            workspaceViewportState.gestureStartZoom);
    final nextAnchorLocalPoint =
        workspaceViewportState.gestureStartLocalFocalPoint + workspaceViewportState.gestureAccumulatedPan;
    final nextCenter = WorkspaceMutations.clampWorkspaceCenter(
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

  void setWindowZoom(WorkspaceState workspace, String windowId, WindowZoomUpdate update) {
    replaceWorkspace(WorkspaceMutations.setWindowZoom(workspace, windowId, update), queueThumbnail: true);
  }

  void setVideoPosition(WorkspaceState? workspace, String windowId, int positionMs) {
    if (workspace == null) {
      return;
    }

    final currentWindow = workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
    if (currentWindow == null || currentWindow.videoPositionMs == positionMs) {
      return;
    }

    replaceWorkspace(WorkspaceMutations.setVideoPosition(workspace, windowId, positionMs), queueThumbnail: false);
  }

  void cycleVideoPlaybackSpeed(WorkspaceState? workspace, String windowId) {
    if (workspace == null ||
        workspace.windows
            .where((window) => window.asset.id == windowId && window.asset.type == AssetType.video)
            .isEmpty) {
      return;
    }

    replaceWorkspace(WorkspaceMutations.cycleVideoPlaybackSpeed(workspace, windowId), queueThumbnail: false);
  }

  void setWindowIntrinsicSize(WorkspaceState? workspace, String windowId, Size intrinsicSize) {
    if (workspace == null || intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return;
    }

    if (workspace.windows.where((window) => window.asset.id == windowId).isEmpty) {
      return;
    }

    replaceWorkspace(
      WorkspaceMutations.setWindowIntrinsicSize(workspace, windowId, intrinsicSize),
      queueThumbnail: true,
    );
  }

  bool isVideoWindowPaused(String windowId) {
    return windowInteractionState.pausedVideoWindows[windowId] ?? true;
  }

  void toggleVideoPlayback(WorkspaceState? workspace, String windowId) {
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
    required WorkspaceState workspace,
    required WorkspaceWindowState window,
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
    updateEnvironment(WorkspaceMutations.toggleWorkspaceOpen(environment, workspaceId));
  }

  void reorderOpenWorkspace(
    Environment? environment,
    List<WorkspaceState> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required void Function(Environment) updateEnvironment,
  }) {
    if (environment == null || sourceWorkspaceId == targetWorkspaceId) {
      return;
    }

    updateEnvironment(
      environment.copyWith(
        workspaces: WorkspaceMutations.reorderOpenWorkspaces(
          workspaces,
          sourceWorkspaceId: sourceWorkspaceId,
          targetWorkspaceId: targetWorkspaceId,
        ),
      ),
    );
  }

  bool canMoveSelectedWindowsToWorkspace({
    required Environment? environment,
    required WorkspaceState? sourceWorkspace,
    required String destinationWorkspaceId,
  }) {
    return environment != null &&
        sourceWorkspace != null &&
        windowInteractionState.selectedExposeWindowIds.isNotEmpty &&
        destinationWorkspaceId != sourceWorkspace.id;
  }

  int selectedExposeWindowCount(WorkspaceState workspace) {
    return workspace.windows
        .where((window) => windowInteractionState.selectedExposeWindowIds.contains(window.asset.id))
        .length;
  }

  void moveSelectedExposeWindowsToWorkspace({
    required Environment environment,
    required WorkspaceState sourceWorkspace,
    required WorkspaceState destinationWorkspace,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
  }) {
    updateEnvironment(
      WorkspaceMutations.moveSelectedWindowsToWorkspace(
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

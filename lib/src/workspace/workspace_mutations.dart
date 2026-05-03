import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/windows/workspace_window_state.dart';
import 'package:serenity_viewer/src/environments/session/session_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_zoom_update.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';
import 'package:serenity_viewer/src/media/assets/media_zoom_utils.dart';
import 'package:serenity_viewer/src/workspace/windows/window_resize_helpers.dart';

part 'workspace_session_mutations.dart';
part 'workspace_viewport_mutations.dart';
part 'viewport/workspace_window_geometry.dart';
part 'workspace_window_mutations.dart';

class SerenityWorkspaceMutations {
  static const List<double> videoPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0];
  static const double minWindowWidth = 96.0;
  static const double minWindowHeight = 72.0;
  static const double maxContentZoom = 30.0;

  static SerenitySessionState replaceWorkspace(SerenitySessionState session, WorkspaceState nextWorkspace) {
    return session.copyWith(
      workspaces: session.workspaces
          .map((workspace) => workspace.id == nextWorkspace.id ? nextWorkspace : workspace)
          .toList(),
    );
  }

  static SerenitySessionState toggleWorkspaceOpen(SerenitySessionState session, String workspaceId) {
    return _toggleWorkspaceOpen(session, workspaceId);
  }

  static List<WorkspaceState> reorderOpenWorkspaces(
    List<WorkspaceState> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
  }) {
    return _reorderOpenWorkspaces(
      workspaces,
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
    );
  }

  static SerenitySessionState moveSelectedWindowsToWorkspace(
    SerenitySessionState session, {
    required String sourceWorkspaceId,
    required String destinationWorkspaceId,
    required Set<String> selectedWindowIds,
  }) {
    return _moveSelectedWindowsToWorkspace(
      session,
      sourceWorkspaceId: sourceWorkspaceId,
      destinationWorkspaceId: destinationWorkspaceId,
      selectedWindowIds: selectedWindowIds,
    );
  }

  static ({WorkspaceState workspace, int? previousZOrder}) focusWindow(WorkspaceState workspace, String windowId) {
    return _focusWindow(workspace, windowId);
  }

  static WorkspaceState restorePreviousWindowZOrder(WorkspaceState workspace, String windowId, int previousZOrder) {
    return _restorePreviousWindowZOrder(workspace, windowId, previousZOrder);
  }

  static double clampWorkspaceZoom(double zoom) {
    return _clampWorkspaceZoom(zoom);
  }

  static Offset clampWorkspaceCenter({required Offset center, required double zoom, required Size viewportSize}) {
    return _clampWorkspaceCenter(center: center, zoom: zoom, viewportSize: viewportSize);
  }

  static WorkspaceState setWorkspaceViewport(
    WorkspaceState workspace, {
    required Size viewportSize,
    Offset? center,
    double? zoom,
  }) {
    return _setWorkspaceViewport(workspace, viewportSize: viewportSize, center: center, zoom: zoom);
  }

  static WorkspaceState fitWorkspaceViewportToContent(WorkspaceState workspace, Size viewportSize) {
    return _fitWorkspaceViewportToContent(workspace, viewportSize);
  }

  static Offset clampWindowPosition(Offset position, Size size) {
    return _clampWindowPosition(position, size);
  }

  static Size windowSizeByFittingAspect({
    required Size currentSize,
    required double contentWidth,
    required double contentHeight,
  }) {
    return _windowSizeByFittingAspect(
      currentSize: currentSize,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    );
  }

  static WorkspaceState moveWindow(WorkspaceState workspace, String windowId, Offset delta) {
    return _moveWindow(workspace, windowId, delta);
  }

  static AssetWindowState scaleWindowAroundCenter(
    AssetWindowState window,
    double scaleDelta, {
    required bool mirrorContentZoom,
  }) {
    return _scaleWindowAroundCenter(window, scaleDelta, mirrorContentZoom: mirrorContentZoom);
  }

  static ({Rect visibleRect, Size zoomedContentSize}) visibleContentRectForWindow(AssetWindowState window) {
    return _visibleContentRectForWindow(window);
  }

  static WorkspaceState collateWorkspaceWindows(WorkspaceState workspace, {required Size targetBox}) {
    return _collateWorkspaceWindows(workspace, targetBox: targetBox);
  }

  static WorkspaceState resizeWindow(
    WorkspaceState workspace,
    String windowId,
    WindowResizeHandle handle,
    Offset delta,
  ) {
    return _resizeWindow(workspace, windowId, handle, delta);
  }

  static WorkspaceState transformWindowFromTrackpad(WorkspaceState workspace, String windowId, double scaleDelta) {
    return _transformWindowFromTrackpad(workspace, windowId, scaleDelta);
  }

  static WorkspaceState fitWindowToContent(WorkspaceState workspace, String windowId) {
    return _fitWindowToContent(workspace, windowId);
  }

  static WorkspaceState setWindowZoom(WorkspaceState workspace, String windowId, WindowZoomUpdate update) {
    return _setWindowZoom(workspace, windowId, update);
  }

  static WorkspaceState setVideoPosition(WorkspaceState workspace, String windowId, int positionMs) {
    return _setVideoPosition(workspace, windowId, positionMs);
  }

  static WorkspaceState cycleVideoPlaybackSpeed(WorkspaceState workspace, String windowId) {
    return _cycleVideoPlaybackSpeed(workspace, windowId);
  }

  static WorkspaceState setWindowIntrinsicSize(WorkspaceState workspace, String windowId, Size intrinsicSize) {
    return _setWindowIntrinsicSize(workspace, windowId, intrinsicSize);
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';

import 'workspace_controller.dart';
import 'workspace_controller_window_arrangement.dart';
import 'workspace_controller_window_editing.dart';
import 'workspace_controller_window_runtime.dart';

const Size workspaceCollateTargetBox = Size(700, 700);

class WorkspaceWindowControllerState {
  WorkspaceWindowControllerState({
    required this.chromeState,
    required this.commitInteractionState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  }) : arrangement = WorkspaceWindowArrangementState(chromeState: chromeState, replaceWorkspace: replaceWorkspace),
       editing = WorkspaceWindowEditingState(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       runtime = WorkspaceWindowRuntimeState(
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
       );

  final ChromeState chromeState;
  final SerenityWorkspaceCommit commitInteractionState;
  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final WorkspaceWindowArrangementState arrangement;
  final WorkspaceWindowEditingState editing;
  final WorkspaceWindowRuntimeState runtime;

  Window? focusedWindowOrNull(Workspace? workspace) {
    return arrangement.focusedWindowOrNull(workspace);
  }

  void focusWindow(Workspace workspace, String windowId) {
    final result = arrangement.focusWindow(workspace, windowId);
    if (result?.previousZOrder == null) {
      return;
    }

    windowInteractionState.previousWindowZOrders[windowId] = result!.previousZOrder!;
  }

  void restorePreviousWindowZOrder(Workspace workspace, String windowId) {
    final previousZ = windowInteractionState.previousWindowZOrders.remove(windowId);
    if (previousZ == null) {
      return;
    }

    arrangement.restorePreviousWindowZOrder(workspace, windowId, previousZ);
  }

  void moveWindow(Workspace workspace, String windowId, Offset delta) {
    editing.moveWindow(workspace, windowId, delta);
  }

  void resizeWindow(Workspace workspace, String windowId, AssetWindowResizeHandle handle, Offset delta) {
    editing.resizeWindow(workspace, windowId, handle, delta);
  }

  void transformWindowFromTrackpad(Workspace workspace, String windowId, double scaleDelta) {
    editing.transformWindowFromTrackpad(workspace, windowId, scaleDelta);
  }

  void fitWindowToContent(Workspace? workspace, String windowId) {
    editing.fitWindowToContent(workspace, windowId);
  }

  void handleOptionGestureHover(
    PointerHoverEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    editing.handleOptionGestureHover(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void flashWindow(String windowId, {required bool mounted}) {
    runtime.flashWindow(windowId, mounted: mounted);
  }

  void setWindowZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    editing.setWindowZoom(workspace, windowId, update);
  }

  void setWindowIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    editing.setWindowIntrinsicSize(workspace, windowId, intrinsicSize);
  }

  void clearWindowRuntimeState(String windowId) {
    runtime.clearWindowRuntimeState(windowId);
  }

  void rememberClosedWindow(
    List<RecentlyClosedWindowEntry> recentlyClosedWindows, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    runtime.rememberClosedWindow(
      recentlyClosedWindows,
      maxRecentlyClosedWindows: maxRecentlyClosedWindows,
      workspace: workspace,
      window: window,
    );
  }

  bool canCollateWorkspaceWindows(Workspace? workspace) {
    return arrangement.canCollateWorkspaceWindows(workspace);
  }

  int collatableWindowCount(Workspace workspace) {
    return arrangement.collatableWindowCount(workspace);
  }

  void collateWorkspaceWindows(Workspace workspace) {
    arrangement.collateWorkspaceWindows(workspace);
  }
}

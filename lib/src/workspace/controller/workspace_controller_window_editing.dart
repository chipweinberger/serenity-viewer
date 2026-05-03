import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';

import 'workspace_controller.dart';

class WorkspaceWindowEditingState {
  const WorkspaceWindowEditingState({
    required this.chromeState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  });

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;

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

  void setWindowZoom(Workspace workspace, String windowId, AssetWindowZoomUpdate update) {
    replaceWorkspace(WorkspaceLayout.setWindowZoom(workspace, windowId, update), queueThumbnail: true);
  }

  void setWindowIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    if (workspace == null || intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return;
    }

    if (workspace.windows.every((window) => window.asset.id != windowId)) {
      return;
    }

    replaceWorkspace(WorkspaceLayout.setWindowIntrinsicSize(workspace, windowId, intrinsicSize), queueThumbnail: true);
  }
}

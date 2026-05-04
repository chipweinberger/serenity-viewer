import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/window/frame/window_resize_helpers.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';

import 'workspace_controller.dart';

class WorkspaceWindowEditingController {
  const WorkspaceWindowEditingController({
    required this.appUiState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  });

  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;

  Window? _windowById(Workspace workspace, String windowId) {
    for (final window in workspace.windows) {
      if (window.asset.id == windowId) {
        return window;
      }
    }
    return null;
  }

  void move(Workspace workspace, String windowId, Offset delta) {
    replaceWorkspace(WorkspaceLayout.moveWindow(workspace, windowId, delta), queueThumbnail: true);
  }

  void moveTo(Workspace workspace, String windowId, Offset position) {
    replaceWorkspace(WorkspaceLayout.moveWindowTo(workspace, windowId, position), queueThumbnail: true);
  }

  void resize(Workspace workspace, String windowId, WindowResizeHandle handle, Offset delta) {
    replaceWorkspace(WorkspaceLayout.resizeWindow(workspace, windowId, handle, delta), queueThumbnail: true);
  }

  void transformFromTrackpad(Workspace workspace, String windowId, double scaleDelta, Offset globalPointerPosition) {
    final nextWorkspace = WorkspaceLayout.transformWindowFromTrackpad(workspace, windowId, scaleDelta);
    replaceWorkspace(nextWorkspace, queueThumbnail: true);

    if (windowInteractionState.activeGestureWindowId != windowId) {
      return;
    }

    final nextWindow = _windowById(nextWorkspace, windowId);
    if (nextWindow == null) {
      windowInteractionState.clearActiveGestureDragAnchor();
      return;
    }

    windowInteractionState.setActiveGestureDragAnchor(
      windowId: windowId,
      globalStartPosition: globalPointerPosition,
      windowStartPosition: nextWindow.position,
    );
  }

  void fitToContent(Workspace? workspace, String windowId) {
    if (workspace == null || workspace.windows.every((window) => window.asset.id != windowId)) {
      return;
    }

    replaceWorkspace(WorkspaceLayout.fitWindowToContent(workspace, windowId), queueThumbnail: true);
  }

  void handleOptionHover(
    PointerHoverEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    final targetWindowId = windowInteractionState.activeGestureWindowId;
    if (appUiState.screen != SerenityScreen.workspace ||
        appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose ||
        isCommandPressedForContentGesture ||
        !isOptionPressedForWindowGesture ||
        targetWindowId == null ||
        event.delta == Offset.zero) {
      return;
    }

    final targetWindow = _windowById(workspace, targetWindowId);
    if (targetWindow == null) {
      windowInteractionState.clearActiveGestureDragAnchor();
      return;
    }

    final dragAnchor = windowInteractionState.activeGestureDragAnchor;
    if (dragAnchor == null || dragAnchor.windowId != targetWindowId) {
      windowInteractionState.setActiveGestureDragAnchor(
        windowId: targetWindowId,
        globalStartPosition: event.position,
        windowStartPosition: targetWindow.position,
      );
    }

    final activeAnchor = windowInteractionState.activeGestureDragAnchor;
    if (activeAnchor == null) {
      return;
    }

    final totalWorkspaceDelta = (event.position - activeAnchor.globalStartPosition) / workspace.viewportZoom;
    moveTo(workspace, targetWindowId, activeAnchor.windowStartPosition + totalWorkspaceDelta);
  }

  void setZoom(Workspace workspace, String windowId, WindowZoomUpdate update) {
    replaceWorkspace(WorkspaceLayout.setWindowZoom(workspace, windowId, update), queueThumbnail: true);
  }

  void setIntrinsicSize(Workspace? workspace, String windowId, Size intrinsicSize) {
    if (workspace == null || intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return;
    }

    if (workspace.windows.every((window) => window.asset.id != windowId)) {
      return;
    }

    replaceWorkspace(WorkspaceLayout.setWindowIntrinsicSize(workspace, windowId, intrinsicSize), queueThumbnail: true);
  }
}

// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_windows.dart';

class AppShellWindowController {
  const AppShellWindowController({
    required this.context,
    required this.mounted,
    required this.chromeState,
    required this.environment,
    required this.activeWorkspace,
    required this.activeWorkspaceOrNull,
    required this.workspaceController,
    required this.showMessage,
  });

  final BuildContext Function() context;
  final bool Function() mounted;
  final ChromeState chromeState;
  final Environment? Function() environment;
  final Workspace Function() activeWorkspace;
  final Workspace? Function() activeWorkspaceOrNull;
  final WorkspaceController workspaceController;
  final ValueChanged<String> showMessage;

  void setActiveGestureWindow(String? windowId) {
    workspaceController.gesture.setActive(windowId);
  }

  void setPinnedHoverWindow(String? windowId) {
    workspaceController.gesture.setPinnedHover(windowId);
  }

  void clearPinnedHoverWindow() {
    setPinnedHoverWindow(null);
  }

  void handleOptionGestureHover(PointerHoverEvent event, Workspace workspace) {
    workspaceController.windows.editing.handleOptionHover(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressed(),
      isOptionPressedForWindowGesture: isOptionPressed(),
    );
  }

  void focusWindow(String windowId) {
    final result = workspaceController.windows.arrangement.focus(activeWorkspace(), windowId);
    if (result?.previousZOrder != null) {
      workspaceController.windowInteractionState.previousWindowZOrders[windowId] = result!.previousZOrder!;
    }
  }

  void restorePreviousWindowZOrder(String windowId) {
    final previousZOrder = workspaceController.windowInteractionState.previousWindowZOrders.remove(windowId);
    if (previousZOrder == null) {
      return;
    }

    workspaceController.windows.arrangement.restorePreviousZOrder(activeWorkspace(), windowId, previousZOrder);
  }

  void moveWindow(String windowId, Offset delta) {
    workspaceController.windows.editing.move(activeWorkspace(), windowId, delta);
  }

  void resizeWindow(String windowId, AssetWindowResizeHandle handle, Offset delta) {
    workspaceController.windows.editing.resize(activeWorkspace(), windowId, handle, delta);
  }

  void transformWindowFromTrackpad(String windowId, double scaleDelta, Offset localFocalPoint) {
    workspaceController.windows.editing.transformFromTrackpad(activeWorkspace(), windowId, scaleDelta);
  }

  void fitWindowToContent(String windowId) {
    workspaceController.windows.editing.fitToContent(activeWorkspaceOrNull(), windowId);
  }

  void fitWorkspaceViewportToContent() {
    workspaceController.viewport.fit.toContent(activeWorkspaceOrNull());
  }

  void handleWorkspacePanZoomStart(PointerPanZoomStartEvent event, Workspace workspace) {
    workspaceController.viewport.gesture.handlePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressed(),
      isOptionPressedForWindowGesture: isOptionPressed(),
    );
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    workspaceController.viewport.gesture.handlePanZoomUpdate(event, workspace, viewportSize);
  }

  void handleWorkspacePanZoomEnd() {
    unawaited(workspaceController.viewport.gesture.handlePanZoomEnd());
  }

  Future<void> confirmCollateWorkspaceWindows() async {
    final workspace = activeWorkspaceOrNull();
    if (workspace == null || chromeState.workspaceLayoutMode != WorkspaceLayoutMode.freeform) {
      return;
    }

    final collatableWindowCount = workspaceController.windows.arrangement.collatableCount(workspace);
    if (collatableWindowCount == 0) {
      showMessage('There are no image or video windows to collate.');
      return;
    }

    final shouldCollate = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Collate Windows?'),
          content: Text(
            'Center and resize $collatableWindowCount image/video window'
            '${collatableWindowCount == 1 ? '' : 's'} into a fixed ${workspaceCollateTargetBox.width.toInt()} × '
            '${workspaceCollateTargetBox.height.toInt()} box?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Collate')),
          ],
        );
      },
    );

    if (shouldCollate == true && mounted()) {
      _collateWorkspaceWindows();
    }
  }

  void setWindowZoom(String windowId, AssetWindowZoomUpdate update) {
    workspaceController.windows.editing.setZoom(activeWorkspace(), windowId, update);
  }

  void setVideoPosition(String windowId, int positionMs) {
    workspaceController.playback.workspace.setPosition(activeWorkspaceOrNull(), windowId, positionMs);
  }

  void cycleVideoPlaybackSpeed(String windowId) {
    workspaceController.playback.workspace.cycleSpeed(activeWorkspaceOrNull(), windowId);
  }

  void setWindowIntrinsicSize(String windowId, Size intrinsicSize) {
    workspaceController.windows.editing.setIntrinsicSize(activeWorkspaceOrNull(), windowId, intrinsicSize);
  }

  bool isVideoWindowPaused(String windowId) {
    return workspaceController.playback.runtime.isPaused(windowId);
  }

  void toggleVideoPlayback(String windowId) {
    if (!workspaceController.playback.workspace.canToggle(activeWorkspaceOrNull(), windowId)) {
      return;
    }

    workspaceController.playback.runtime.toggle(windowId);
  }

  void pauseAllVideos() {
    workspaceController.playback.runtime.stopAll(environment());
  }

  void flashWindow(String windowId, {required bool mounted}) {
    workspaceController.windows.runtime.flash(windowId, mounted: mounted);
  }

  void _collateWorkspaceWindows() {
    final workspace = activeWorkspaceOrNull();
    if (!workspaceController.windows.arrangement.canCollate(workspace)) {
      return;
    }

    workspaceController.windows.arrangement.collate(workspace!);
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_viewport_fit.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_viewport_gesture.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceViewportControllerState {
  WorkspaceViewportControllerState({
    required this.chromeState,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.replaceWorkspace,
    required this.setWorkspaceViewport,
    required this.refreshActiveWorkspaceThumbnail,
  }) : gesture = WorkspaceViewportGestureState(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         workspaceViewportState: workspaceViewportState,
         setWorkspaceViewport: setWorkspaceViewport,
         refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
       ),
       fit = WorkspaceViewportFitState(
         workspaceViewportState: workspaceViewportState,
         replaceWorkspace: replaceWorkspace,
         setWorkspaceViewport: setWorkspaceViewport,
       );

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final WorkspaceViewportGestureState gesture;
  final WorkspaceViewportFitState fit;

  void handleWorkspacePanZoomStart(
    PointerPanZoomStartEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    gesture.handleWorkspacePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void handleWorkspacePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    gesture.handleWorkspacePanZoomUpdate(event, workspace, viewportSize);
  }

  Future<void> handleWorkspacePanZoomEnd() async {
    await gesture.handleWorkspacePanZoomEnd();
  }

  void fitWorkspaceViewportToContent(Workspace? workspace) {
    fit.fitWorkspaceViewportToContent(workspace);
  }
}

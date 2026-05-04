import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_environment.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_expose.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_gesture.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_playback.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_viewport.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_windows.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

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
  }) : gesture = WorkspaceGestureControllerState(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       expose = WorkspaceExposeControllerState(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       windows = WorkspaceWindowControllerState(
         chromeState: chromeState,
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       viewport = WorkspaceViewportControllerState(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         workspaceViewportState: workspaceViewportState,
         replaceWorkspace: replaceWorkspace,
         setWorkspaceViewport: setWorkspaceViewport,
         refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
       ),
       playback = WorkspacePlaybackControllerState(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       environment = WorkspaceEnvironmentControllerState();

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final WorkspaceGestureControllerState gesture;
  final WorkspaceExposeControllerState expose;
  final WorkspaceWindowControllerState windows;
  final WorkspaceViewportControllerState viewport;
  final WorkspacePlaybackControllerState playback;
  final WorkspaceEnvironmentControllerState environment;
}

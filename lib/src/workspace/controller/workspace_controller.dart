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
  }) : gesture = WorkspaceGestureController(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       expose = WorkspaceExposeController(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       windows = WorkspaceWindowsController(
         chromeState: chromeState,
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       viewport = WorkspaceViewportController(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         workspaceViewportState: workspaceViewportState,
         replaceWorkspace: replaceWorkspace,
         setWorkspaceViewport: setWorkspaceViewport,
         refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
       ),
       playback = WorkspacePlaybackController(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       environment = WorkspaceEnvironmentController();

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final WorkspaceGestureController gesture;
  final WorkspaceExposeController expose;
  final WorkspaceWindowsController windows;
  final WorkspaceViewportController viewport;
  final WorkspacePlaybackController playback;
  final WorkspaceEnvironmentController environment;
}

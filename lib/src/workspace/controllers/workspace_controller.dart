import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/workspace/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_environment_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_expose_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_gesture_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

typedef SerenityWorkspaceCommit = void Function(VoidCallback update);
typedef SerenityWorkspaceReplace = void Function(Workspace workspace, {bool queueThumbnail});
typedef SerenityWorkspaceViewportSetter =
    void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail});

class WorkspaceController {
  WorkspaceController({
    required this.appUiState,
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
         appUiState: appUiState,
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       viewport = WorkspaceViewportController(
         appUiState: appUiState,
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

  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
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

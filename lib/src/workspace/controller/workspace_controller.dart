import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_environment_operations.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_playback_operations.dart';
import 'package:serenity_viewer/src/workspace/operations/workspace_stacking_operations.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_api_environment.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_api_expose.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_api_gesture.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_api_playback.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_api_viewport.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_api_windows.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

part 'workspace_collate.dart';
part 'workspace_controller_environment.dart';
part 'workspace_controller_expose.dart';
part 'workspace_controller_gesture.dart';
part 'workspace_controller_playback.dart';
part 'workspace_controller_viewport.dart';
part 'workspace_controller_windows.dart';
part 'workspace_zoom_to_fit.dart';

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
  }) : gestureController = WorkspaceGestureControllerState(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       exposeController = WorkspaceExposeControllerState(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       windowController = WorkspaceWindowControllerState(
         chromeState: chromeState,
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       viewportController = WorkspaceViewportControllerState(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         workspaceViewportState: workspaceViewportState,
         setWorkspaceViewport: setWorkspaceViewport,
         refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
       ),
       playbackController = WorkspacePlaybackControllerState(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       environmentController = WorkspaceEnvironmentControllerState() {
    gesture = WorkspaceGestureApi(this);
    expose = WorkspaceExposeApi(this);
    windows = WorkspaceWindowApi(this);
    viewport = WorkspaceViewportApi(this);
    playback = WorkspacePlaybackApi(this);
    environment = WorkspaceEnvironmentApi(this);
  }

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final WorkspaceGestureControllerState gestureController;
  final WorkspaceExposeControllerState exposeController;
  final WorkspaceWindowControllerState windowController;
  final WorkspaceViewportControllerState viewportController;
  final WorkspacePlaybackControllerState playbackController;
  final WorkspaceEnvironmentControllerState environmentController;
  late final WorkspaceGestureApi gesture;
  late final WorkspaceExposeApi expose;
  late final WorkspaceWindowApi windows;
  late final WorkspaceViewportApi viewport;
  late final WorkspacePlaybackApi playback;
  late final WorkspaceEnvironmentApi environment;
}

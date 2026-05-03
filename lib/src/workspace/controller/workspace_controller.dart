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
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

part 'workspace_collate.dart';
part 'workspace_controller_api_environment.dart';
part 'workspace_controller_api_expose.dart';
part 'workspace_controller_api_gesture.dart';
part 'workspace_controller_api_playback.dart';
part 'workspace_controller_api_viewport.dart';
part 'workspace_controller_api_windows.dart';
part 'workspace_controller_environment.dart';
part 'workspace_controller_expose.dart';
part 'workspace_controller_gesture.dart';
part 'workspace_controller_legacy_api.dart';
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
  }) : _gestureController = _WorkspaceGestureController(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       _exposeController = _WorkspaceExposeController(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       _windowController = _WorkspaceWindowController(
         chromeState: chromeState,
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       _viewportController = _WorkspaceViewportController(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         workspaceViewportState: workspaceViewportState,
         setWorkspaceViewport: setWorkspaceViewport,
         refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
       ),
       _playbackController = _WorkspacePlaybackController(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       _environmentController = _WorkspaceEnvironmentController() {
    gesture = WorkspaceGestureApi._(this);
    expose = WorkspaceExposeApi._(this);
    windows = WorkspaceWindowApi._(this);
    viewport = WorkspaceViewportApi._(this);
    playback = WorkspacePlaybackApi._(this);
    environment = WorkspaceEnvironmentApi._(this);
  }

  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final _WorkspaceGestureController _gestureController;
  final _WorkspaceExposeController _exposeController;
  final _WorkspaceWindowController _windowController;
  final _WorkspaceViewportController _viewportController;
  final _WorkspacePlaybackController _playbackController;
  final _WorkspaceEnvironmentController _environmentController;
  late final WorkspaceGestureApi gesture;
  late final WorkspaceExposeApi expose;
  late final WorkspaceWindowApi windows;
  late final WorkspaceViewportApi viewport;
  late final WorkspacePlaybackApi playback;
  late final WorkspaceEnvironmentApi environment;
}

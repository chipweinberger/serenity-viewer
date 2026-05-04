import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_environment_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_expose_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_gesture_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';

typedef SerenityWorkspaceCommit = void Function(VoidCallback update);
typedef SerenityWorkspaceReplace = void Function(Workspace workspace, {bool queueThumbnail});
typedef SerenityWorkspaceViewportSetter =
    void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail});

class WorkspaceController {
  const WorkspaceController({
    required this.gesture,
    required this.expose,
    required this.windows,
    required this.viewport,
    required this.playback,
    required this.environment,
    required this.window,
    required this.history,
    required this.media,
    required this.layout,
    required this.videoConversion,
    required this.assetPicker,
    required this.shortcuts,
    required this.links,
    required this.linksLauncher,
    required this.linksPrompts,
    required this.thumbnails,
    required this.tracking,
  });

  final WorkspaceGestureController gesture;
  final WorkspaceExposeController expose;
  final WorkspaceWindowsController windows;
  final WorkspaceViewportController viewport;
  final WorkspacePlaybackController playback;
  final WorkspaceEnvironmentController environment;
  final WorkspaceWindowController window;
  final EnvironmentWindowHistoryController history;
  final WorkspaceMediaImportController media;
  final WorkspaceExposeLayoutController layout;
  final WorkspaceVideoConversionController videoConversion;
  final WorkspaceAssetPickerController assetPicker;
  final WorkspaceShortcutController shortcuts;
  final WorkspaceLinksController links;
  final WorkspaceLinksLauncher linksLauncher;
  final WorkspaceLinksPrompts linksPrompts;
  final ThumbnailController thumbnails;
  final WorkspaceViewTrackingController tracking;
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
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
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

typedef SerenityWorkspaceCommit = void Function(VoidCallback update);
typedef SerenityWorkspaceReplace = void Function(Workspace workspace, {bool queueThumbnail});
typedef SerenityWorkspaceViewportSetter =
    void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail});

class WorkspaceController {
  WorkspaceController({
    required EnvironmentStoreState environmentStoreState,
    required AppUiState appUiState,
    required this.windowInteractionState,
    required WorkspaceViewportState workspaceViewportState,
    required ThumbnailController thumbnailController,
    required SerenityWorkspaceReplace replaceWorkspace,
    required SerenityWorkspaceViewportSetter setWorkspaceViewport,
    required Future<void> Function() refreshActiveWorkspaceThumbnail,
  }) : gesture = WorkspaceGestureController(windowInteractionState: windowInteractionState),
       expose = WorkspaceExposeController(windowInteractionState: windowInteractionState),
       windows = WorkspaceWindowsController(
         appUiState: appUiState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       viewport = WorkspaceViewportController(
         environmentStoreState: environmentStoreState,
         appUiState: appUiState,
         windowInteractionState: windowInteractionState,
         workspaceViewportState: workspaceViewportState,
         thumbnailController: thumbnailController,
         replaceWorkspace: replaceWorkspace,
         applyWorkspaceViewport: setWorkspaceViewport,
         refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
       ),
       playback = WorkspacePlaybackController(
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       environment = WorkspaceEnvironmentController();

  final WindowInteractionState windowInteractionState;
  final WorkspaceGestureController gesture;
  final WorkspaceExposeController expose;
  final WorkspaceWindowsController windows;
  final WorkspaceViewportController viewport;
  final WorkspacePlaybackController playback;
  final WorkspaceEnvironmentController environment;
  WorkspaceWindowController get window => _window ?? _missingFacade('window');
  EnvironmentWindowHistoryController get history => _history ?? _missingFacade('history');
  WorkspaceMediaImportController get media => _media ?? _missingFacade('media');
  WorkspaceExposeLayoutController get layout => _layout ?? _missingFacade('layout');
  WorkspaceVideoConversionController get videoConversion => _videoConversion ?? _missingFacade('videoConversion');
  WorkspaceAssetPickerController get assetPicker => _assetPicker ?? _missingFacade('assetPicker');
  WorkspaceShortcutController get shortcuts => _shortcuts ?? _missingFacade('shortcuts');
  WorkspaceLinksController get links => _links ?? _missingFacade('links');
  WorkspaceLinksLauncher get linksLauncher => _linksLauncher ?? _missingFacade('linksLauncher');
  WorkspaceLinksPrompts get linksPrompts => _linksPrompts ?? _missingFacade('linksPrompts');
  ThumbnailController get thumbnails => _thumbnails ?? _missingFacade('thumbnails');
  WorkspaceViewTrackingController get tracking => _tracking ?? _missingFacade('tracking');

  WorkspaceWindowController? _window;
  EnvironmentWindowHistoryController? _history;
  WorkspaceMediaImportController? _media;
  WorkspaceExposeLayoutController? _layout;
  WorkspaceVideoConversionController? _videoConversion;
  WorkspaceAssetPickerController? _assetPicker;
  WorkspaceShortcutController? _shortcuts;
  WorkspaceLinksController? _links;
  WorkspaceLinksLauncher? _linksLauncher;
  WorkspaceLinksPrompts? _linksPrompts;
  ThumbnailController? _thumbnails;
  WorkspaceViewTrackingController? _tracking;

  void attachWorkspaceUiControllers({
    required WorkspaceWindowController window,
    required WorkspaceMediaImportController media,
    required WorkspaceExposeLayoutController layout,
    required WorkspaceVideoConversionController videoConversion,
    required WorkspaceAssetPickerController assetPicker,
    required WorkspaceShortcutController shortcuts,
    required WorkspaceLinksController links,
    required WorkspaceLinksLauncher linksLauncher,
    required WorkspaceLinksPrompts linksPrompts,
    required ThumbnailController thumbnails,
    required WorkspaceViewTrackingController tracking,
  }) {
    _window = window;
    _media = media;
    _layout = layout;
    _videoConversion = videoConversion;
    _assetPicker = assetPicker;
    _shortcuts = shortcuts;
    _links = links;
    _linksLauncher = linksLauncher;
    _linksPrompts = linksPrompts;
    _thumbnails = thumbnails;
    _tracking = tracking;
  }

  void attachEnvironmentHistoryController(EnvironmentWindowHistoryController history) {
    _history = history;
  }

  Never _missingFacade(String name) {
    throw StateError('WorkspaceController.$name was used before the UI-facing workspace controllers were attached.');
  }
}

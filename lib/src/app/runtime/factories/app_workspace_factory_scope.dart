import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';

class WorkspaceFactoryInputs {
  const WorkspaceFactoryInputs({
    required this.platformBridge,
    required this.environmentStore,
    required this.mediaInspector,
    required this.appUiController,
    required this.isRunningInWidgetTest,
    required this.context,
    required this.mounted,
    required this.showMessage,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.newId,
    required this.colorFromDigest,
    required this.activeWorkspace,
    required this.workspaces,
    required this.openWorkspaces,
    required this.focusedWindowOrNull,
    required this.setWorkspaceViewport,
    required this.showWorkspaceScreen,
    required this.showLibraryScreen,
    required this.toggleExpose,
    required this.toggleVideoPlayback,
    required this.environmentStoreState,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
    required this.environmentWindowHistoryState,
  });

  final PlatformBridge platformBridge;
  final EnvironmentStore environmentStore;
  final MediaInspector mediaInspector;
  final AppUiController appUiController;
  final bool isRunningInWidgetTest;
  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final String Function(String prefix) newId;
  final int Function(String value) colorFromDigest;
  final Workspace? Function() activeWorkspace;
  final List<Workspace> Function() workspaces;
  final List<Workspace> Function() openWorkspaces;
  final Window? Function() focusedWindowOrNull;
  final void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final SerenityShowLibraryScreen showLibraryScreen;
  final VoidCallback toggleExpose;
  final ValueChanged<String> toggleVideoPlayback;
  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final EnvironmentWindowHistoryState environmentWindowHistoryState;
}

class WorkspaceFactoryScope {
  const WorkspaceFactoryScope({
    required this.platform,
    required this.store,
    required this.media,
    required this.ui,
    required this.isRunningInWidgetTest,
    required this.context,
    required this.mounted,
    required this.showMessage,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.newId,
    required this.colorFromDigest,
    required this.activeWorkspace,
    required this.workspaces,
    required this.openWorkspaces,
    required this.focusedWindowOrNull,
    required this.setWorkspaceViewport,
    required this.showWorkspaceScreen,
    required this.showLibraryScreen,
    required this.toggleExpose,
    required this.toggleVideoPlayback,
    required this.envState,
    required this.uiState,
    required this.interactionState,
    required this.trackingState,
    required this.viewportState,
    required this.thumbState,
  });

  WorkspaceFactoryScope.fromInputs(WorkspaceFactoryInputs inputs)
    : platform = inputs.platformBridge,
      store = inputs.environmentStore,
      media = inputs.mediaInspector,
      ui = inputs.appUiController,
      isRunningInWidgetTest = inputs.isRunningInWidgetTest,
      context = inputs.context,
      mounted = inputs.mounted,
      showMessage = inputs.showMessage,
      updateEnvironment = inputs.updateEnvironment,
      replaceWorkspace = inputs.replaceWorkspace,
      newId = inputs.newId,
      colorFromDigest = inputs.colorFromDigest,
      activeWorkspace = inputs.activeWorkspace,
      workspaces = inputs.workspaces,
      openWorkspaces = inputs.openWorkspaces,
      focusedWindowOrNull = inputs.focusedWindowOrNull,
      setWorkspaceViewport = inputs.setWorkspaceViewport,
      showWorkspaceScreen = inputs.showWorkspaceScreen,
      showLibraryScreen = inputs.showLibraryScreen,
      toggleExpose = inputs.toggleExpose,
      toggleVideoPlayback = inputs.toggleVideoPlayback,
      envState = inputs.environmentStoreState,
      uiState = inputs.appUiState,
      interactionState = inputs.windowInteractionState,
      trackingState = inputs.workspaceViewTrackingState,
      viewportState = inputs.workspaceViewportState,
      thumbState = inputs.thumbnailRefreshState;

  final PlatformBridge platform;
  final EnvironmentStore store;
  final MediaInspector media;
  final AppUiController ui;
  final bool isRunningInWidgetTest;
  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final String Function(String prefix) newId;
  final int Function(String value) colorFromDigest;
  final Workspace? Function() activeWorkspace;
  final List<Workspace> Function() workspaces;
  final List<Workspace> Function() openWorkspaces;
  final Window? Function() focusedWindowOrNull;
  final void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final SerenityShowLibraryScreen showLibraryScreen;
  final VoidCallback toggleExpose;
  final ValueChanged<String> toggleVideoPlayback;
  final EnvironmentStoreState envState;
  final AppUiState uiState;
  final WindowInteractionState interactionState;
  final WorkspaceViewTrackingState trackingState;
  final WorkspaceViewportState viewportState;
  final ThumbnailRefreshState thumbState;
}

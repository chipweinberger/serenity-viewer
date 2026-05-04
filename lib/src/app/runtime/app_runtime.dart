import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_document_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_foundation_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

class AppRuntime {
  AppRuntime({
    required this.appUiController,
    required this.platformBridge,
    required this.sharedVideoControllerPool,
    required this.environmentStore,
    required this.environmentBookmarkSynchronizer,
    required this.documentCoordinator,
    required this.workspaceController,
    required this.environmentController,
    required this.environmentWindowHistoryController,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final AppUiController appUiController;
  final PlatformBridge platformBridge;
  final SharedVideoControllerPool sharedVideoControllerPool;
  final EnvironmentStore environmentStore;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final DocumentCoordinator documentCoordinator;
  final WorkspaceController workspaceController;
  final EnvironmentController environmentController;
  final EnvironmentWindowHistoryController environmentWindowHistoryController;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspaceController.tracking.cancel();
    workspaceController.thumbnails.dispose();
    sharedVideoControllerPool.dispose();
  }
}

AppRuntime createAppRuntime({
  required bool isRunningInWidgetTest,
  required EnvironmentStoreState environmentStoreState,
  required AppUiState appUiState,
  required WindowInteractionState windowInteractionState,
  required WorkspaceViewTrackingState workspaceViewTrackingState,
  required WorkspaceViewportState workspaceViewportState,
  required ThumbnailRefreshState thumbnailRefreshState,
  required EnvironmentWindowHistoryState environmentWindowHistoryState,
  required String Function() windowTitle,
  required BuildContext Function() context,
  required bool Function() mounted,
  required ValueChanged<String> showMessage,
  required Environment Function() seedEnvironment,
  required ValueChanged<Environment> updateEnvironment,
  required void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace,
  required Future<void> Function() saveEnvironment,
  required String Function(String prefix) newId,
  required int Function(String value) colorFromDigest,
  required Workspace? Function() activeWorkspace,
  required List<Workspace> Function() workspaces,
  required List<Workspace> Function() openWorkspaces,
  required Window? Function() focusedWindowOrNull,
  required void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport,
  required SerenityShowWorkspaceScreen showWorkspaceScreen,
  required SerenityShowLibraryScreen showLibraryScreen,
  required VoidCallback toggleExpose,
  required ValueChanged<String> toggleVideoPlayback,
}) {
  late final ({
    AppUiController appUiController,
    MediaInspector mediaInspector,
    PlatformBridge platformBridge,
    SharedVideoControllerPool sharedVideoControllerPool,
    EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer,
    EnvironmentStore environmentStore,
  })
  foundation;
  late final ({
    WorkspaceController workspaceController,
    EnvironmentController environmentController,
    EnvironmentWindowHistoryController environmentWindowHistoryController,
  })
  workspace;

  foundation = createAppFoundation(
    isRunningInWidgetTest: isRunningInWidgetTest,
    environmentStoreState: environmentStoreState,
    appUiState: appUiState,
    windowInteractionState: windowInteractionState,
    windowTitle: windowTitle,
    showMessage: showMessage,
    mounted: mounted,
    refreshWorkspaceTracking: () async => workspace.workspaceController.tracking.refresh(),
    markWorkspaceThumbnailDirty: (workspaceId) =>
        workspace.workspaceController.thumbnails.markWorkspaceDirty(workspaceId),
    syncWindowTitle: () async => foundation.platformBridge.syncWindowTitle(),
  );
  workspace = createAppWorkspaceServices(
    inputs: WorkspaceFactoryInputs(
      platformBridge: foundation.platformBridge,
      environmentStore: foundation.environmentStore,
      mediaInspector: foundation.mediaInspector,
      appUiController: foundation.appUiController,
      isRunningInWidgetTest: isRunningInWidgetTest,
      context: context,
      mounted: mounted,
      showMessage: showMessage,
      updateEnvironment: updateEnvironment,
      replaceWorkspace: replaceWorkspace,
      newId: newId,
      colorFromDigest: colorFromDigest,
      activeWorkspace: activeWorkspace,
      workspaces: workspaces,
      openWorkspaces: openWorkspaces,
      focusedWindowOrNull: focusedWindowOrNull,
      setWorkspaceViewport: setWorkspaceViewport,
      showWorkspaceScreen: showWorkspaceScreen,
      showLibraryScreen: showLibraryScreen,
      toggleExpose: toggleExpose,
      toggleVideoPlayback: toggleVideoPlayback,
      environmentStoreState: environmentStoreState,
      appUiState: appUiState,
      windowInteractionState: windowInteractionState,
      workspaceViewTrackingState: workspaceViewTrackingState,
      workspaceViewportState: workspaceViewportState,
      thumbnailRefreshState: thumbnailRefreshState,
      environmentWindowHistoryState: environmentWindowHistoryState,
    ),
  );
  final documentCoordinator = createAppDocumentCoordinator(
    environmentStoreState: environmentStoreState,
    environmentStore: foundation.environmentStore,
    context: context,
    mounted: mounted,
    seedEnvironment: seedEnvironment,
    showMessage: showMessage,
    refreshActiveWorkspaceThumbnailIfNeeded: () async =>
        workspace.workspaceController.thumbnails.refreshActiveWorkspaceIfNeeded(),
    storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
    syncWindowTitle: foundation.platformBridge.syncWindowTitle,
    resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
    createFileBookmark: foundation.platformBridge.createFileBookmark,
    thumbnailDirectory: foundation.platformBridge.thumbnailDirectory,
    updateEnvironment: updateEnvironment,
    saveEnvironment: saveEnvironment,
  );
  final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (environmentStoreState.hasUnsavedChanges) {
      unawaited(saveEnvironment());
    }
  });
  final appLifecycleListener = AppLifecycleListener(
    onStateChange: workspace.workspaceController.tracking.handleAppLifecycleStateChanged,
    onExitRequested: () async {
      await saveEnvironment();
      return ui.AppExitResponse.exit;
    },
  );

  return AppRuntime(
    appUiController: foundation.appUiController,
    platformBridge: foundation.platformBridge,
    sharedVideoControllerPool: foundation.sharedVideoControllerPool,
    environmentStore: foundation.environmentStore,
    environmentBookmarkSynchronizer: foundation.environmentBookmarkSynchronizer,
    documentCoordinator: documentCoordinator,
    workspaceController: workspace.workspaceController,
    environmentController: workspace.environmentController,
    environmentWindowHistoryController: workspace.environmentWindowHistoryController,
    autosaveTimer: autosaveTimer,
    appLifecycleListener: appLifecycleListener,
  );
}

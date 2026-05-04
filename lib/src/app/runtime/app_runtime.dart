import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_document_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_foundation_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

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
  required EnvironmentStoreState environmentStoreState,
  required WorkspaceState workspaceState,
  required WorkspaceRuntime workspaceRuntime,
  required WorkspaceQueries workspaceQueries,
  required WorkspaceActions workspaceActions,
  required String Function() windowTitle,
  required Future<void> Function() saveEnvironment,
  required DocumentCreationActions documentCreation,
}) {
  late final AppFoundation foundation;
  late final AppUiController appUiController;
  late final EnvironmentStore environmentStore;
  late final WorkspaceParts workspace;

  foundation = createAppFoundation(
    isRunningInWidgetTest: workspaceRuntime.isRunningInWidgetTest,
    environmentStoreState: environmentStoreState,
    windowTitle: windowTitle,
    showMessage: workspaceRuntime.showMessage,
    mounted: workspaceRuntime.mounted,
  );
  appUiController = AppUiController(
    appUiState: workspaceState.appUiState,
    windowInteractionState: workspaceState.windowInteractionState,
    refreshWorkspaceTracking: () => workspace.workspaceController.tracking.refresh(),
  );
  environmentStore = EnvironmentStore(
    environmentStoreState: environmentStoreState,
    appUiState: workspaceState.appUiState,
    markWorkspaceThumbnailDirty: (workspaceId) =>
        workspace.workspaceController.thumbnails.markWorkspaceDirty(workspaceId),
    refreshWorkspaceTracking: () => workspace.workspaceController.tracking.refresh(),
    syncWindowTitle: foundation.platformBridge.syncWindowTitle,
  );
  workspace = assembleWorkspace(
    dependencies: WorkspaceDependencies(
      services: WorkspaceServices(
        platformBridge: foundation.platformBridge,
        environmentStore: environmentStore,
        mediaInspector: foundation.mediaInspector,
        appUiController: appUiController,
      ),
      runtime: workspaceRuntime,
      state: workspaceState,
      queries: workspaceQueries,
      actions: workspaceActions,
    ),
  );
  final documentCoordinator = createAppDocumentCoordinator(
    environmentStore: environmentStore,
    ui: DocumentUiActions(
      context: workspaceRuntime.context,
      mounted: workspaceRuntime.mounted,
      showMessage: workspaceRuntime.showMessage,
    ),
    load: DocumentLoadActions(
      resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
      saveEnvironment: saveEnvironment,
    ),
    save: DocumentSaveActions(
      refreshActiveWorkspaceThumbnailIfNeeded: () async =>
          workspace.workspaceController.thumbnails.refreshActiveWorkspaceIfNeeded(),
      storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
      syncWindowTitle: foundation.platformBridge.syncWindowTitle,
    ),
    creation: documentCreation,
    thumbnails: DocumentThumbnailActions(thumbnailDirectory: foundation.platformBridge.thumbnailDirectory),
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
    appUiController: appUiController,
    platformBridge: foundation.platformBridge,
    sharedVideoControllerPool: foundation.sharedVideoControllerPool,
    environmentStore: environmentStore,
    environmentBookmarkSynchronizer: foundation.environmentBookmarkSynchronizer,
    documentCoordinator: documentCoordinator,
    workspaceController: workspace.workspaceController,
    environmentController: workspace.environmentController,
    environmentWindowHistoryController: workspace.environmentWindowHistoryController,
    autosaveTimer: autosaveTimer,
    appLifecycleListener: appLifecycleListener,
  );
}

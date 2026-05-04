import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_root.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
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
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspaceController.tracking.cancel();
    workspaceController.thumbnails.dispose();
    sharedVideoControllerPool.dispose();
    unawaited(platformBridge.dispose());
  }
}

AppRuntime createAppRuntime({
  required AppRootObjects rootObjects,
  required BuildContext Function() context,
  required String Function() windowTitle,
  required bool Function() mounted,
  required bool isRunningInWidgetTest,
  required Environment Function() seedEnvironment,
  required Future<void> Function() saveEnvironment,
  required ValueChanged<String> showMessage,
}) {
  late final AppFoundation foundation;
  late final AppUiController appUiController;
  late final EnvironmentStore environmentStore;
  late final WorkspaceParts workspace;

  final workspaceRuntime = WorkspaceRuntime(
    isRunningInWidgetTest: isRunningInWidgetTest,
    context: context,
    mounted: mounted,
    showMessage: showMessage,
  );

  final workspaceQueries = WorkspaceQueries(
    activeWorkspace: () => deriveActiveWorkspaceOrNull(rootObjects.environmentStoreState),
    workspaces: () => deriveWorkspaces(rootObjects.environmentStoreState),
    openWorkspaces: () => deriveOpenWorkspaces(rootObjects.environmentStoreState),
    focusedWindowOrNull: () => workspace.workspaceController.window.focusedWindowOrNull(),
  );

  foundation = createAppFoundation(
    rootObjects: rootObjects,
    isRunningInWidgetTest: isRunningInWidgetTest,
    windowTitle: windowTitle,
    showMessage: workspaceRuntime.showMessage,
    mounted: workspaceRuntime.mounted,
  );

  appUiController = AppUiController(
    appUiState: rootObjects.appUiState,
    windowWorkspaceDragState: rootObjects.windowWorkspaceDragState,
    windowInteractionState: rootObjects.windowInteractionState,
    refreshWorkspaceTracking: () => workspace.workspaceController.tracking.refresh(),
  );

  environmentStore = EnvironmentStore(
    environmentStoreState: rootObjects.environmentStoreState,
    appUiState: rootObjects.appUiState,
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
        sharedVideoControllerPool: foundation.sharedVideoControllerPool,
        mediaInspector: foundation.mediaInspector,
        appUiController: appUiController,
      ),
      runtime: workspaceRuntime,
      rootObjects: rootObjects,
      queries: workspaceQueries,
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
    creation: DocumentCreationActions(seedEnvironment: seedEnvironment),
    thumbnails: DocumentThumbnailActions(thumbnailDirectory: foundation.platformBridge.thumbnailDirectory),
  );

  final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (rootObjects.environmentStoreState.hasUnsavedChanges) {
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
    autosaveTimer: autosaveTimer,
    appLifecycleListener: appLifecycleListener,
  );
}

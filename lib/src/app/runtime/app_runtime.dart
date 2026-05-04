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
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
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

class AppRuntimeState {
  const AppRuntimeState({
    required this.environmentStoreState,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
    required this.environmentWindowHistoryState,
  });

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final EnvironmentWindowHistoryState environmentWindowHistoryState;

  WorkspaceState get workspace {
    return WorkspaceState(
      appUiState: appUiState,
      windowInteractionState: windowInteractionState,
      workspaceViewTrackingState: workspaceViewTrackingState,
      workspaceViewportState: workspaceViewportState,
      thumbnailRefreshState: thumbnailRefreshState,
      environmentWindowHistoryState: environmentWindowHistoryState,
    );
  }
}

class AppRuntimeRuntime {
  const AppRuntimeRuntime({
    required this.isRunningInWidgetTest,
    required this.windowTitle,
    required this.context,
    required this.mounted,
    required this.showMessage,
  });

  final bool isRunningInWidgetTest;
  final String Function() windowTitle;
  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;

  WorkspaceRuntime get workspace {
    return WorkspaceRuntime(
      isRunningInWidgetTest: isRunningInWidgetTest,
      context: context,
      mounted: mounted,
      showMessage: showMessage,
    );
  }

  DocumentUiActions get documentUi {
    return DocumentUiActions(context: context, mounted: mounted, showMessage: showMessage);
  }
}

class AppRuntimeQueries {
  const AppRuntimeQueries({
    required this.activeWorkspace,
    required this.workspaces,
    required this.openWorkspaces,
    required this.focusedWindowOrNull,
  });

  final Workspace? Function() activeWorkspace;
  final List<Workspace> Function() workspaces;
  final List<Workspace> Function() openWorkspaces;
  final Window? Function() focusedWindowOrNull;

  WorkspaceQueries get workspace {
    return WorkspaceQueries(
      activeWorkspace: activeWorkspace,
      workspaces: workspaces,
      openWorkspaces: openWorkspaces,
      focusedWindowOrNull: focusedWindowOrNull,
    );
  }
}

class AppRuntimeActions {
  const AppRuntimeActions({
    required this.seedEnvironment,
    required this.saveEnvironment,
    required this.newId,
    required this.colorFromDigest,
    required this.setWorkspaceViewport,
    required this.showWorkspaceScreen,
    required this.showLibraryScreen,
    required this.toggleExpose,
    required this.toggleVideoPlayback,
  });

  final Environment Function() seedEnvironment;
  final Future<void> Function() saveEnvironment;
  final String Function(String prefix) newId;
  final int Function(String value) colorFromDigest;
  final void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final SerenityShowLibraryScreen showLibraryScreen;
  final VoidCallback toggleExpose;
  final ValueChanged<String> toggleVideoPlayback;

  WorkspaceActions get workspace {
    return WorkspaceActions(
      newId: newId,
      colorFromDigest: colorFromDigest,
      setWorkspaceViewport: setWorkspaceViewport,
      showWorkspaceScreen: showWorkspaceScreen,
      showLibraryScreen: showLibraryScreen,
      toggleExpose: toggleExpose,
      toggleVideoPlayback: toggleVideoPlayback,
    );
  }

  DocumentCreationActions get documentCreation {
    return DocumentCreationActions(seedEnvironment: seedEnvironment);
  }
}

class AppRuntimeDependencies {
  const AppRuntimeDependencies({
    required this.state,
    required this.runtime,
    required this.queries,
    required this.actions,
  });

  final AppRuntimeState state;
  final AppRuntimeRuntime runtime;
  final AppRuntimeQueries queries;
  final AppRuntimeActions actions;
}

AppRuntime createAppRuntime({required AppRuntimeDependencies dependencies}) {
  late final AppFoundation foundation;
  late final AppUiController appUiController;
  late final EnvironmentStore environmentStore;
  late final WorkspaceParts workspace;

  foundation = createAppFoundation(
    isRunningInWidgetTest: dependencies.runtime.isRunningInWidgetTest,
    environmentStoreState: dependencies.state.environmentStoreState,
    windowTitle: dependencies.runtime.windowTitle,
    showMessage: dependencies.runtime.showMessage,
    mounted: dependencies.runtime.mounted,
  );
  appUiController = AppUiController(
    appUiState: dependencies.state.appUiState,
    windowInteractionState: dependencies.state.windowInteractionState,
    refreshWorkspaceTracking: () => workspace.workspaceController.tracking.refresh(),
  );
  environmentStore = EnvironmentStore(
    environmentStoreState: dependencies.state.environmentStoreState,
    appUiState: dependencies.state.appUiState,
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
      runtime: dependencies.runtime.workspace,
      state: dependencies.state.workspace,
      queries: dependencies.queries.workspace,
      actions: dependencies.actions.workspace,
    ),
  );
  final documentCoordinator = createAppDocumentCoordinator(
    environmentStore: environmentStore,
    ui: dependencies.runtime.documentUi,
    load: DocumentLoadActions(
      resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
      saveEnvironment: dependencies.actions.saveEnvironment,
    ),
    save: DocumentSaveActions(
      refreshActiveWorkspaceThumbnailIfNeeded: () async =>
          workspace.workspaceController.thumbnails.refreshActiveWorkspaceIfNeeded(),
      storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
      syncWindowTitle: foundation.platformBridge.syncWindowTitle,
    ),
    creation: dependencies.actions.documentCreation,
    thumbnails: DocumentThumbnailActions(thumbnailDirectory: foundation.platformBridge.thumbnailDirectory),
  );
  final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (dependencies.state.environmentStoreState.hasUnsavedChanges) {
      unawaited(dependencies.actions.saveEnvironment());
    }
  });
  final appLifecycleListener = AppLifecycleListener(
    onStateChange: workspace.workspaceController.tracking.handleAppLifecycleStateChanged,
    onExitRequested: () async {
      await dependencies.actions.saveEnvironment();
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

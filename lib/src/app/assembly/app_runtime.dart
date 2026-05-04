import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/assembly/app_document_factory.dart';
import 'package:serenity_viewer/src/app/assembly/app_foundation_factory.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime_bridge.dart';
import 'package:serenity_viewer/src/app/assembly/app_workspace_factory.dart';
import 'package:serenity_viewer/src/app/app_dependencies.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/session/environment_store.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/workspace/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/media/video/media_bridge.dart';
import 'package:serenity_viewer/src/media/video/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/environment/session/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/environment/session/environment_api.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/window/session/recently_closed_windows_state.dart';
import 'package:serenity_viewer/src/workspace/window/session/workspace_window_history_controller.dart';

class AppRuntime {
  AppRuntime.assembled({
    required this.dependencies,
    required this.state,
    required this.foundation,
    required this.documents,
    required this.workspace,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final AppDependencies dependencies;
  final AppStateServices state;
  final AppFoundation foundation;
  final AppDocument documents;
  final AppWorkspaceServices workspace;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  static AppRuntime create(AppRuntimeConfig config) {
    final dependencies = config.dependencies;
    final environmentStoreState = dependencies.environmentStoreState;
    final bridge = AppRuntimeBridge();

    final foundation = AppFoundationFactory(config).create(
      refreshWorkspaceTracking: bridge.refreshWorkspaceTracking,
      markWorkspaceThumbnailDirty: bridge.markWorkspaceThumbnailDirty,
      syncWindowTitle: bridge.syncWindowTitle,
    );
    bridge.bindFoundation(foundation);
    final workspace = AppWorkspaceFactory(config).create(foundation: foundation);
    bridge.bindWorkspace(workspace);
    final documentCoordinator = AppDocumentFactory(config).create(foundation: foundation, workspace: workspace);
    final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (environmentStoreState.hasUnsavedChanges) {
        unawaited(config.environment.saveEnvironment());
      }
    });
    final appLifecycleListener = AppLifecycleListener(
      onStateChange: workspace.environmentController.tracking.handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await config.environment.saveEnvironment();
        return ui.AppExitResponse.exit;
      },
    );

    return AppRuntime.assembled(
      dependencies: dependencies,
      state: AppStateServices(
        handles: dependencies.handles,
        environmentStoreState: dependencies.environmentStoreState,
        appUiState: dependencies.appUiState,
        windowInteractionState: dependencies.windowInteractionState,
        workspaceViewTrackingState: dependencies.workspaceViewTrackingState,
        workspaceViewportState: dependencies.workspaceViewportState,
        thumbnailRefreshState: dependencies.thumbnailRefreshState,
        recentlyClosedWindowsState: dependencies.recentlyClosedWindowsState,
      ),
      foundation: foundation,
      documents: AppDocument(documentCoordinator: documentCoordinator),
      workspace: workspace,
      autosaveTimer: autosaveTimer,
      appLifecycleListener: appLifecycleListener,
    );
  }

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspace.environmentController.tracking.cancel();
    dependencies.workspaceViewTrackingState.dispose();
    dependencies.windowInteractionState.dispose();
    workspace.thumbnailController.dispose();
    foundation.mediaBridge.dispose();
    state.handles.dispose();
  }
}

class AppStateServices {
  const AppStateServices({
    required this.handles,
    required this.environmentStoreState,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
    required this.recentlyClosedWindowsState,
  });

  final AppHandles handles;
  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final RecentlyClosedWindowsState recentlyClosedWindowsState;
}

class AppFoundation {
  const AppFoundation({
    required this.appUiController,
    required this.mediaBridge,
    required this.platformBridge,
    required this.environmentBookmarkSynchronizer,
    required this.environmentStore,
  });

  final AppUiController appUiController;
  final MediaBridge mediaBridge;
  final PlatformBridge platformBridge;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final EnvironmentStore environmentStore;
}

class AppDocument {
  const AppDocument({required this.documentCoordinator});

  final DocumentCoordinator documentCoordinator;
}

class AppWorkspaceServices {
  const AppWorkspaceServices({
    required this.thumbnailController,
    required this.videoConversionCoordinator,
    required this.workspaceLinksController,
    required this.workspaceController,
    required this.workspaceWindowController,
    required this.workspaceWindowHistoryController,
    required this.workspaceViewportSessionController,
    required this.environmentController,
  });

  final ThumbnailController thumbnailController;
  final VideoConversionCoordinator videoConversionCoordinator;
  final LinksController workspaceLinksController;
  final WorkspaceController workspaceController;
  final WorkspaceWindowController workspaceWindowController;
  final WorkspaceWindowHistoryController workspaceWindowHistoryController;
  final WorkspaceViewportSessionController workspaceViewportSessionController;
  final EnvironmentApi environmentController;
}

class AppRuntimeConfig {
  const AppRuntimeConfig({
    required this.isRunningInWidgetTest,
    required this.dependencies,
    required this.shell,
    required this.environment,
    required this.workspace,
  });

  final bool isRunningInWidgetTest;
  final AppDependencies dependencies;
  final AppConfig shell;
  final EnvironmentConfig environment;
  final WorkspaceConfig workspace;
}

class AppConfig {
  const AppConfig({
    required this.windowTitle,
    required this.context,
    required this.mounted,
    required this.commitStateChange,
    required this.showMessage,
  });

  final String Function() windowTitle;
  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final ValueChanged<String> showMessage;
}

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.seedEnvironment,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.saveEnvironment,
  });

  final Environment Function() seedEnvironment;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final Future<void> Function() saveEnvironment;
}

class WorkspaceConfig {
  const WorkspaceConfig({
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
  });

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
}

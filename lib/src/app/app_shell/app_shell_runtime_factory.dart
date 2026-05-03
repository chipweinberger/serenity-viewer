import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/platform/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/app/sry_document/sry_document_coordinator.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/video_tools/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';

class AppShellRuntimeFactory {
  const AppShellRuntimeFactory(this.config);

  final AppShellRuntimeConfig config;

  AppShellRuntime create() {
    final dependencies = config.dependencies;
    final persistenceState = dependencies.persistenceState;
    final chromeState = dependencies.chromeState;
    final windowInteractionState = dependencies.windowInteractionState;
    final workspaceViewTrackingState = dependencies.workspaceViewTrackingState;
    final workspaceViewportState = dependencies.workspaceViewportState;
    final thumbnailRefreshState = dependencies.thumbnailRefreshState;

    late final WorkspaceShellController workspaceShellController;
    late final ThumbnailController thumbnailController;
    late final AppShellPlatformBridge appShellPlatformBridge;

    final chromeController = ChromeController(
      chromeState: chromeState,
      windowInteractionState: windowInteractionState,
      commitStateChange: config.commitStateChange,
      refreshWorkspaceTracking: () => workspaceShellController.tracking.refresh(),
    );
    final mediaBridge = MediaBridge(
      isRunningInWidgetTest: config.isRunningInWidgetTest,
      showMessage: config.showMessage,
      isMounted: config.mounted,
    );
    final environmentController = EnvironmentController(
      persistenceState: persistenceState,
      chromeState: chromeState,
      markWorkspaceThumbnailDirty: (workspaceId) => thumbnailController.markWorkspaceDirty(workspaceId),
      commitStateChange: config.commitStateChange,
      refreshWorkspaceTracking: () => workspaceShellController.tracking.refresh(),
      syncWindowTitle: () => appShellPlatformBridge.syncWindowTitle(),
    );
    appShellPlatformBridge = AppShellPlatformBridge(
      persistenceState: persistenceState,
      isRunningInWidgetTest: config.isRunningInWidgetTest,
      windowTitle: config.windowTitle,
    );
    final environmentBookmarkSynchronizer = EnvironmentBookmarkSynchronizer(
      createFileBookmark: appShellPlatformBridge.createFileBookmark,
    );
    thumbnailController = ThumbnailController(
      state: thumbnailRefreshState,
      refresher: ThumbnailRefresher(
        persistenceState: persistenceState,
        updateEnvironment: environmentController.updateEnvironment,
        renderer: ThumbnailRenderer(isRunningInWidgetTest: config.isRunningInWidgetTest),
        store: ThumbnailStore(thumbnailDirectory: appShellPlatformBridge.thumbnailDirectory),
      ),
      activeScreen: () => chromeState.screen,
      activeWorkspaceId: () => config.activeWorkspace()?.id,
      viewportSize: () => workspaceViewportState.viewportSize,
      commitStateChange: config.commitStateChange,
      isMounted: config.mounted,
    );
    final sryDocumentCoordinator = SryDocumentCoordinator(
      persistenceState: persistenceState,
      environmentController: environmentController,
      context: config.context,
      mounted: config.mounted,
      seedEnvironment: config.seedEnvironment,
      showMessage: config.showMessage,
      refreshActiveWorkspaceThumbnailIfNeeded: thumbnailController.refreshActiveWorkspaceIfNeeded,
      storeLastEnvironmentPath: appShellPlatformBridge.storeLastEnvironmentPath,
      syncWindowTitle: appShellPlatformBridge.syncWindowTitle,
      resolveFileBookmark: appShellPlatformBridge.resolveFileBookmark,
      createFileBookmark: appShellPlatformBridge.createFileBookmark,
      thumbnailDirectory: appShellPlatformBridge.thumbnailDirectory,
      updateEnvironment: config.updateEnvironment,
      saveEnvironment: config.saveEnvironment,
    );
    final videoConversionCoordinator = VideoConversionCoordinator(
      context: config.context,
      mounted: config.mounted,
      showMessage: config.showMessage,
      mediaBridge: mediaBridge,
      createFileBookmark: appShellPlatformBridge.createFileBookmark,
      activeWorkspace: config.activeWorkspace,
      replaceWorkspace: config.replaceWorkspace,
      colorFromDigest: config.colorFromDigest,
      removePausedVideoWindow: (windowId) {
        config.commitStateChange(() {
          windowInteractionState.pausedVideoWindows.remove(windowId);
        });
      },
    );
    final workspaceLinksController = LinksController(
      screen: () => chromeState.screen,
      hasSession: () => persistenceState.environment != null,
      activeWorkspace: config.activeWorkspace,
      workspaces: config.workspaces,
      replaceWorkspace: config.replaceWorkspace,
      newId: config.newId,
      showMessage: config.showMessage,
      context: config.context,
      mounted: config.mounted,
    );
    final workspaceController = WorkspaceController(
      chromeState: chromeState,
      windowInteractionState: windowInteractionState,
      workspaceViewportState: workspaceViewportState,
      commitInteractionState: config.commitStateChange,
      replaceWorkspace: config.replaceWorkspace,
      setWorkspaceViewport: config.setWorkspaceViewport,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    );
    workspaceShellController = WorkspaceShellController(
      persistenceState: persistenceState,
      chromeState: chromeState,
      workspaceViewTrackingState: workspaceViewTrackingState,
      workspaceViewportState: workspaceViewportState,
      workspaceController: workspaceController,
      workspaceLinksController: workspaceLinksController,
      context: config.context,
      mounted: config.mounted,
      workspaces: config.workspaces,
      openWorkspaces: config.openWorkspaces,
      activeWorkspace: config.activeWorkspace,
      focusedWindowOrNull: config.focusedWindowOrNull,
      updateEnvironment: config.updateEnvironment,
      replaceWorkspace: config.replaceWorkspace,
      showWorkspaceScreen: config.showWorkspaceScreen,
      showLibraryScreen: config.showLibraryScreen,
      toggleExpose: config.toggleExpose,
      showMessage: config.showMessage,
      newId: config.newId,
      workspaceSwitchTarget: chromeController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
      toggleVideoPlayback: config.toggleVideoPlayback,
    );
    final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (persistenceState.hasUnsavedChanges) {
        unawaited(config.saveEnvironment());
      }
    });
    final appLifecycleListener = AppLifecycleListener(
      onStateChange: workspaceShellController.tracking.handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await config.saveEnvironment();
        return ui.AppExitResponse.exit;
      },
    );

    return AppShellRuntime.assembled(
      dependencies: dependencies,
      chromeController: chromeController,
      sryDocumentCoordinator: sryDocumentCoordinator,
      mediaBridge: mediaBridge,
      workspaceController: workspaceController,
      workspaceShellController: workspaceShellController,
      workspaceLinksController: workspaceLinksController,
      appShellPlatformBridge: appShellPlatformBridge,
      environmentBookmarkSynchronizer: environmentBookmarkSynchronizer,
      environmentController: environmentController,
      thumbnailController: thumbnailController,
      videoConversionCoordinator: videoConversionCoordinator,
      autosaveTimer: autosaveTimer,
      appLifecycleListener: appLifecycleListener,
    );
  }
}

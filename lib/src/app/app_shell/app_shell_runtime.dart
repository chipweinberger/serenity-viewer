import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/app/platform/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/app/sry_document/sry_document_coordinator.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/video_tools/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/session/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppShellRuntime {
  AppShellRuntime._({
    required this.dependencies,
    required this.chromeController,
    required this.sryDocumentCoordinator,
    required this.mediaBridge,
    required this.workspaceController,
    required this.workspaceShellController,
    required this.workspaceLinksController,
    required this.appShellPlatformBridge,
    required this.environmentBookmarkSynchronizer,
    required this.environmentController,
    required this.thumbnailController,
    required this.videoConversionCoordinator,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final ShellDependencies dependencies;
  final ChromeController chromeController;
  final SryDocumentCoordinator sryDocumentCoordinator;
  final MediaBridge mediaBridge;
  final WorkspaceController workspaceController;
  final WorkspaceShellController workspaceShellController;
  final LinksController workspaceLinksController;
  final AppShellPlatformBridge appShellPlatformBridge;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final EnvironmentController environmentController;
  final ThumbnailController thumbnailController;
  final VideoConversionCoordinator videoConversionCoordinator;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  ShellHandles get handles => dependencies.handles;
  AppEnvironmentState get persistenceState => dependencies.persistenceState;
  ChromeState get chromeState => dependencies.chromeState;
  WorkspaceViewTrackingState get workspaceViewTrackingState => dependencies.workspaceViewTrackingState;
  WorkspaceViewportState get workspaceViewportState => dependencies.workspaceViewportState;
  ThumbnailRefreshState get thumbnailRefreshState => dependencies.thumbnailRefreshState;

  static AppShellRuntime create({
    required bool isRunningInWidgetTest,
    required ShellDependencies dependencies,
    required String Function() windowTitle,
    required BuildContext Function() context,
    required bool Function() mounted,
    required StateSetter commitStateChange,
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
      commitStateChange: commitStateChange,
      refreshWorkspaceTracking: () => workspaceShellController.tracking.refresh(),
    );
    final mediaBridge = MediaBridge(
      isRunningInWidgetTest: isRunningInWidgetTest,
      showMessage: showMessage,
      isMounted: mounted,
    );
    final environmentController = EnvironmentController(
      persistenceState: persistenceState,
      chromeState: chromeState,
      markWorkspaceThumbnailDirty: (workspaceId) => thumbnailController.markWorkspaceDirty(workspaceId),
      commitStateChange: commitStateChange,
      refreshWorkspaceTracking: () => workspaceShellController.tracking.refresh(),
      syncWindowTitle: () => appShellPlatformBridge.syncWindowTitle(),
    );
    appShellPlatformBridge = AppShellPlatformBridge(
      persistenceState: persistenceState,
      isRunningInWidgetTest: isRunningInWidgetTest,
      windowTitle: windowTitle,
    );
    final environmentBookmarkSynchronizer = EnvironmentBookmarkSynchronizer(
      createFileBookmark: appShellPlatformBridge.createFileBookmark,
    );
    thumbnailController = ThumbnailController(
      state: thumbnailRefreshState,
      refresher: ThumbnailRefresher(
        persistenceState: persistenceState,
        updateEnvironment: environmentController.updateEnvironment,
        renderer: ThumbnailRenderer(isRunningInWidgetTest: isRunningInWidgetTest),
        store: ThumbnailStore(thumbnailDirectory: appShellPlatformBridge.thumbnailDirectory),
      ),
      activeScreen: () => chromeState.screen,
      activeWorkspaceId: () => activeWorkspace()?.id,
      viewportSize: () => workspaceViewportState.viewportSize,
      commitStateChange: commitStateChange,
      isMounted: mounted,
    );
    final sryDocumentCoordinator = SryDocumentCoordinator(
      persistenceState: persistenceState,
      environmentController: environmentController,
      context: context,
      mounted: mounted,
      seedEnvironment: seedEnvironment,
      showMessage: showMessage,
      refreshActiveWorkspaceThumbnailIfNeeded: thumbnailController.refreshActiveWorkspaceIfNeeded,
      storeLastEnvironmentPath: appShellPlatformBridge.storeLastEnvironmentPath,
      syncWindowTitle: appShellPlatformBridge.syncWindowTitle,
      resolveFileBookmark: appShellPlatformBridge.resolveFileBookmark,
      createFileBookmark: appShellPlatformBridge.createFileBookmark,
      thumbnailDirectory: appShellPlatformBridge.thumbnailDirectory,
      updateEnvironment: updateEnvironment,
      saveEnvironment: saveEnvironment,
    );
    final videoConversionCoordinator = VideoConversionCoordinator(
      context: context,
      mounted: mounted,
      showMessage: showMessage,
      mediaBridge: mediaBridge,
      createFileBookmark: appShellPlatformBridge.createFileBookmark,
      activeWorkspace: activeWorkspace,
      replaceWorkspace: replaceWorkspace,
      colorFromDigest: colorFromDigest,
      removePausedVideoWindow: (windowId) {
        commitStateChange(() {
          windowInteractionState.pausedVideoWindows.remove(windowId);
        });
      },
    );
    final workspaceLinksController = LinksController(
      screen: () => chromeState.screen,
      hasSession: () => persistenceState.environment != null,
      activeWorkspace: activeWorkspace,
      workspaces: workspaces,
      replaceWorkspace: replaceWorkspace,
      newId: newId,
      showMessage: showMessage,
      context: context,
      mounted: mounted,
    );
    final workspaceController = WorkspaceController(
      chromeState: chromeState,
      windowInteractionState: windowInteractionState,
      workspaceViewportState: workspaceViewportState,
      commitInteractionState: commitStateChange,
      replaceWorkspace: replaceWorkspace,
      setWorkspaceViewport: setWorkspaceViewport,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    );
    workspaceShellController = WorkspaceShellController(
      persistenceState: persistenceState,
      chromeState: chromeState,
      workspaceViewTrackingState: workspaceViewTrackingState,
      workspaceViewportState: workspaceViewportState,
      workspaceController: workspaceController,
      workspaceLinksController: workspaceLinksController,
      context: context,
      mounted: mounted,
      workspaces: workspaces,
      openWorkspaces: openWorkspaces,
      activeWorkspace: activeWorkspace,
      focusedWindowOrNull: focusedWindowOrNull,
      updateEnvironment: updateEnvironment,
      replaceWorkspace: replaceWorkspace,
      showWorkspaceScreen: showWorkspaceScreen,
      showLibraryScreen: showLibraryScreen,
      toggleExpose: toggleExpose,
      showMessage: showMessage,
      newId: newId,
      workspaceSwitchTarget: chromeController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
      toggleVideoPlayback: toggleVideoPlayback,
    );
    final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (persistenceState.hasUnsavedChanges) {
        unawaited(saveEnvironment());
      }
    });
    final appLifecycleListener = AppLifecycleListener(
      onStateChange: workspaceShellController.tracking.handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await saveEnvironment();
        return ui.AppExitResponse.exit;
      },
    );

    return AppShellRuntime._(
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

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspaceShellController.tracking.cancel();
    dependencies.workspaceViewTrackingState.dispose();
    dependencies.windowInteractionState.dispose();
    thumbnailController.dispose();
    mediaBridge.dispose();
    handles.dispose();
  }
}

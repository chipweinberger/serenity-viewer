import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime_foundation_factory.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/video_tools/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';

class AppShellRuntimeWorkspaceFactory {
  const AppShellRuntimeWorkspaceFactory(this.config);

  final AppShellRuntimeConfig config;

  AppShellRuntimeWorkspace create({
    required AppShellRuntimeFoundation foundation,
    required Future<void> Function() refreshWorkspaceTracking,
  }) {
    final dependencies = config.dependencies;
    final persistenceState = dependencies.persistenceState;
    final chromeState = dependencies.chromeState;
    final windowInteractionState = dependencies.windowInteractionState;
    final workspaceViewTrackingState = dependencies.workspaceViewTrackingState;
    final workspaceViewportState = dependencies.workspaceViewportState;
    final thumbnailRefreshState = dependencies.thumbnailRefreshState;

    late final WorkspaceShellController workspaceShellController;

    final thumbnailController = ThumbnailController(
      state: thumbnailRefreshState,
      refresher: ThumbnailRefresher(
        persistenceState: persistenceState,
        updateEnvironment: foundation.environmentController.updateEnvironment,
        renderer: ThumbnailRenderer(isRunningInWidgetTest: config.isRunningInWidgetTest),
        store: ThumbnailStore(thumbnailDirectory: foundation.appShellPlatformBridge.thumbnailDirectory),
      ),
      activeScreen: () => chromeState.screen,
      activeWorkspaceId: () => config.activeWorkspace()?.id,
      viewportSize: () => workspaceViewportState.viewportSize,
      commitStateChange: config.commitStateChange,
      isMounted: config.mounted,
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
      workspaceSwitchTarget: foundation.chromeController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
      toggleVideoPlayback: config.toggleVideoPlayback,
    );
    final videoConversionCoordinator = VideoConversionCoordinator(
      context: config.context,
      mounted: config.mounted,
      showMessage: config.showMessage,
      mediaBridge: foundation.mediaBridge,
      createFileBookmark: foundation.appShellPlatformBridge.createFileBookmark,
      activeWorkspace: config.activeWorkspace,
      replaceWorkspace: config.replaceWorkspace,
      colorFromDigest: config.colorFromDigest,
      removePausedVideoWindow: (windowId) {
        config.commitStateChange(() {
          windowInteractionState.pausedVideoWindows.remove(windowId);
        });
      },
    );

    return AppShellRuntimeWorkspace(
      thumbnailController: thumbnailController,
      workspaceLinksController: workspaceLinksController,
      workspaceController: workspaceController,
      workspaceShellController: workspaceShellController,
      videoConversionCoordinator: videoConversionCoordinator,
    );
  }
}

class AppShellRuntimeWorkspace {
  const AppShellRuntimeWorkspace({
    required this.thumbnailController,
    required this.workspaceLinksController,
    required this.workspaceController,
    required this.workspaceShellController,
    required this.videoConversionCoordinator,
  });

  final ThumbnailController thumbnailController;
  final LinksController workspaceLinksController;
  final WorkspaceController workspaceController;
  final WorkspaceShellController workspaceShellController;
  final VideoConversionCoordinator videoConversionCoordinator;
}

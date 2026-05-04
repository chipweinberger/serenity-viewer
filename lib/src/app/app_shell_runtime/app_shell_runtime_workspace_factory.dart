import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime_foundation_factory.dart';
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

  AppShellRuntimeWorkspace create({required AppShellRuntimeFoundation foundation}) {
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
      activeWorkspaceId: () => config.workspace.activeWorkspace()?.id,
      viewportSize: () => workspaceViewportState.viewportSize,
      commitStateChange: config.shell.commitStateChange,
      isMounted: config.shell.mounted,
    );
    final workspaceLinksController = LinksController(
      screen: () => chromeState.screen,
      hasSession: () => persistenceState.environment != null,
      activeWorkspace: config.workspace.activeWorkspace,
      workspaces: config.workspace.workspaces,
      replaceWorkspace: config.environment.replaceWorkspace,
      newId: config.workspace.newId,
      showMessage: config.shell.showMessage,
      context: config.shell.context,
      mounted: config.shell.mounted,
    );
    final workspaceController = WorkspaceController(
      chromeState: chromeState,
      windowInteractionState: windowInteractionState,
      workspaceViewportState: workspaceViewportState,
      commitInteractionState: config.shell.commitStateChange,
      replaceWorkspace: config.environment.replaceWorkspace,
      setWorkspaceViewport: config.workspace.setWorkspaceViewport,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    );
    workspaceShellController = WorkspaceShellController(
      persistenceState: persistenceState,
      chromeState: chromeState,
      workspaceViewTrackingState: workspaceViewTrackingState,
      workspaceViewportState: workspaceViewportState,
      workspaceController: workspaceController,
      workspaceLinksController: workspaceLinksController,
      context: config.shell.context,
      mounted: config.shell.mounted,
      workspaces: config.workspace.workspaces,
      openWorkspaces: config.workspace.openWorkspaces,
      activeWorkspace: config.workspace.activeWorkspace,
      focusedWindowOrNull: config.workspace.focusedWindowOrNull,
      updateEnvironment: config.environment.updateEnvironment,
      replaceWorkspace: config.environment.replaceWorkspace,
      showWorkspaceScreen: config.workspace.showWorkspaceScreen,
      showLibraryScreen: config.workspace.showLibraryScreen,
      toggleExpose: config.workspace.toggleExpose,
      showMessage: config.shell.showMessage,
      newId: config.workspace.newId,
      workspaceSwitchTarget: foundation.chromeController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
      toggleVideoPlayback: config.workspace.toggleVideoPlayback,
    );
    final videoConversionCoordinator = VideoConversionCoordinator(
      context: config.shell.context,
      mounted: config.shell.mounted,
      showMessage: config.shell.showMessage,
      mediaBridge: foundation.mediaBridge,
      createFileBookmark: foundation.appShellPlatformBridge.createFileBookmark,
      activeWorkspace: config.workspace.activeWorkspace,
      replaceWorkspace: config.environment.replaceWorkspace,
      colorFromDigest: config.workspace.colorFromDigest,
      removePausedVideoWindow: (windowId) {
        config.shell.commitStateChange(() {
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

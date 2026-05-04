import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/media/video/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_api.dart';

class AppWorkspaceFactory {
  const AppWorkspaceFactory(this.config);

  final AppRuntimeConfig config;

  AppWorkspaceServices create({required AppFoundation foundation}) {
    final dependencies = config.dependencies;
    final environmentStoreState = dependencies.environmentStoreState;
    final appUiState = dependencies.appUiState;
    final windowInteractionState = dependencies.windowInteractionState;
    final workspaceViewTrackingState = dependencies.workspaceViewTrackingState;
    final workspaceViewportState = dependencies.workspaceViewportState;
    final thumbnailRefreshState = dependencies.thumbnailRefreshState;

    late final EnvironmentApi environmentController;

    final thumbnailController = ThumbnailController(
      state: thumbnailRefreshState,
      refresher: ThumbnailRefresher(
        environmentStoreState: environmentStoreState,
        updateEnvironment: foundation.environmentStore.updateEnvironment,
        renderer: ThumbnailRenderer(isRunningInWidgetTest: config.isRunningInWidgetTest),
        store: ThumbnailStore(thumbnailDirectory: foundation.platformBridge.thumbnailDirectory),
      ),
      activeScreen: () => appUiState.screen,
      activeWorkspaceId: () => config.workspace.activeWorkspace()?.id,
      viewportSize: () => workspaceViewportState.viewportSize,
      commitStateChange: config.shell.commitStateChange,
      isMounted: config.shell.mounted,
    );
    final workspaceLinksController = LinksController(
      screen: () => appUiState.screen,
      hasSession: () => environmentStoreState.environment != null,
      activeWorkspace: config.workspace.activeWorkspace,
      workspaces: config.workspace.workspaces,
      replaceWorkspace: config.environment.replaceWorkspace,
      newId: config.workspace.newId,
      showMessage: config.shell.showMessage,
      context: config.shell.context,
      mounted: config.shell.mounted,
    );
    final workspaceController = WorkspaceController(
      appUiState: appUiState,
      windowInteractionState: windowInteractionState,
      workspaceViewportState: workspaceViewportState,
      commitInteractionState: config.shell.commitStateChange,
      replaceWorkspace: config.environment.replaceWorkspace,
      setWorkspaceViewport: config.workspace.setWorkspaceViewport,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    );
    environmentController = EnvironmentApi(
      environmentStoreState: environmentStoreState,
      appUiState: appUiState,
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
      workspaceSwitchTarget: foundation.appUiController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
      toggleVideoPlayback: config.workspace.toggleVideoPlayback,
    );
    final videoConversionCoordinator = VideoConversionCoordinator(
      context: config.shell.context,
      mounted: config.shell.mounted,
      showMessage: config.shell.showMessage,
      mediaBridge: foundation.mediaBridge,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      activeWorkspace: config.workspace.activeWorkspace,
      replaceWorkspace: config.environment.replaceWorkspace,
      colorFromDigest: config.workspace.colorFromDigest,
      removePausedVideoWindow: (windowId) {
        config.shell.commitStateChange(() {
          windowInteractionState.pausedVideoWindows.remove(windowId);
        });
      },
    );

    return AppWorkspaceServices(
      thumbnailController: thumbnailController,
      workspaceLinksController: workspaceLinksController,
      workspaceController: workspaceController,
      environmentController: environmentController,
      videoConversionCoordinator: videoConversionCoordinator,
    );
  }
}

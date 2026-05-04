import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_session.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';

class AppWorkspaceFactory {
  const AppWorkspaceFactory(this.config);

  final AppRuntimeConfig config;

  AppWorkspaceServices create({required AppFoundation foundation}) {
    final ownedState = config.ownedState;
    final environmentStoreState = ownedState.environmentStoreState;
    final appUiState = ownedState.appUiState;
    final windowInteractionState = ownedState.windowInteractionState;
    final workspaceViewTrackingState = ownedState.workspaceViewTrackingState;
    final workspaceViewportState = ownedState.workspaceViewportState;
    final thumbnailRefreshState = ownedState.thumbnailRefreshState;

    late final EnvironmentSession environmentSession;

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
    final workspaceLinksController = WorkspaceLinksController(
      screen: () => appUiState.screen,
      hasSession: () => environmentStoreState.environment != null,
      activeWorkspace: config.workspace.activeWorkspace,
      workspaces: config.workspace.workspaces,
      replaceWorkspace: config.environment.replaceWorkspace,
      newId: config.workspace.newId,
      showMessage: config.shell.showMessage,
      mounted: config.shell.mounted,
    );
    final workspaceLinksPrompts = WorkspaceLinksPrompts(context: config.shell.context);
    final workspaceController = WorkspaceController(
      appUiState: appUiState,
      windowInteractionState: windowInteractionState,
      workspaceViewportState: workspaceViewportState,
      commitInteractionState: config.shell.commitStateChange,
      replaceWorkspace: config.environment.replaceWorkspace,
      setWorkspaceViewport: config.workspace.setWorkspaceViewport,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    );
    final workspaceWindowController = WorkspaceWindowController(
      appUiState: appUiState,
      environment: () => environmentStoreState.environment,
      activeWorkspace: () => config.workspace.activeWorkspace()!,
      activeWorkspaceOrNull: config.workspace.activeWorkspace,
      workspaceController: workspaceController,
    );
    final workspaceWindowHistoryController = WorkspaceWindowHistoryController(
      environment: () => environmentStoreState.environment,
      workspaces: config.workspace.workspaces,
      activeWorkspace: config.workspace.activeWorkspace,
      workspaceWindowHistoryState: ownedState.workspaceWindowHistoryState,
      workspaceController: workspaceController,
      updateEnvironment: foundation.environmentStore.updateEnvironment,
      replaceWorkspace: foundation.environmentStore.replaceWorkspace,
      commitStateChange: config.shell.commitStateChange,
      showMessage: config.shell.showMessage,
      showWorkspaceScreen: config.workspace.showWorkspaceScreen,
      screen: () => appUiState.screen,
      maxRecentlyClosedWindows: 12,
    );
    final workspaceViewportSessionController = WorkspaceViewportSessionController(
      environmentStoreState: environmentStoreState,
      workspaceViewportState: workspaceViewportState,
      thumbnailController: thumbnailController,
      replaceWorkspace: foundation.environmentStore.replaceWorkspace,
    );
    environmentSession = EnvironmentSession(
      EnvironmentSessionDependencies(
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
      ),
    );
    final workspaceVideoConversionController = WorkspaceVideoConversionController(
      context: config.shell.context,
      mounted: config.shell.mounted,
      showMessage: config.shell.showMessage,
      mediaInspector: foundation.mediaInspector,
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
    final workspaceMediaImportController = WorkspaceMediaImportController(
      imageExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'],
      videoExtensions: const ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'],
      environmentStoreState: environmentStoreState,
      activeWorkspace: () => config.workspace.activeWorkspace()!,
      workspaceVideoConversionController: workspaceVideoConversionController,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      mediaInspector: foundation.mediaInspector,
      updateEnvironment: foundation.environmentStore.updateEnvironment,
      thumbnailController: thumbnailController,
      showMessage: config.shell.showMessage,
    );

    return AppWorkspaceServices(
      thumbnailController: thumbnailController,
      workspaceMediaImportController: workspaceMediaImportController,
      workspaceLinksController: workspaceLinksController,
      workspaceLinksPrompts: workspaceLinksPrompts,
      workspaceController: workspaceController,
      workspaceWindowController: workspaceWindowController,
      workspaceWindowHistoryController: workspaceWindowHistoryController,
      workspaceViewportSessionController: workspaceViewportSessionController,
      environmentSession: environmentSession,
      workspaceVideoConversionController: workspaceVideoConversionController,
    );
  }
}

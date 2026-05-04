import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_prompts.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';

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
    );
    final workspaceLinksLauncher = WorkspaceLinksLauncher(
      showMessage: config.shell.showMessage,
      mounted: config.shell.mounted,
    );
    final workspaceLinksPrompts = WorkspaceLinksPrompts(context: config.shell.context);
    final videoFrameExporter = VideoFrameExporter(mediaInspector: foundation.mediaInspector);
    final workspaceVideoConversionPrompts = WorkspaceVideoConversionPrompts(context: config.shell.context);
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
    final environmentNavigationController = EnvironmentNavigationController(
      EnvironmentNavigationDependencies(
        environmentStoreState: environmentStoreState,
        appUiState: appUiState,
        workspaceController: workspaceController,
        openWorkspaces: config.workspace.openWorkspaces,
        updateEnvironment: config.environment.updateEnvironment,
        showWorkspaceScreen: config.workspace.showWorkspaceScreen,
        showLibraryScreen: config.workspace.showLibraryScreen,
        workspaceSwitchTarget: foundation.appUiController.workspaceSwitchTarget,
        refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
      ),
    );
    final workspaceExposeLayoutController = WorkspaceExposeLayoutController(
      WorkspaceExposeLayoutDependencies(
        appUiState: appUiState,
        workspaceViewportState: workspaceViewportState,
        context: config.shell.context,
        mounted: config.shell.mounted,
        activeWorkspace: config.workspace.activeWorkspace,
        replaceWorkspace: config.environment.replaceWorkspace,
        showWorkspaceScreen: config.workspace.showWorkspaceScreen,
      ),
    );
    final environmentManagementMutations = EnvironmentManagementMutations(
      EnvironmentManagementMutationDependencies(
        environmentStoreState: environmentStoreState,
        appUiState: appUiState,
        workspaceController: workspaceController,
        workspaces: config.workspace.workspaces,
        updateEnvironment: config.environment.updateEnvironment,
        replaceWorkspace: config.environment.replaceWorkspace,
        showWorkspaceScreen: config.workspace.showWorkspaceScreen,
        newId: config.workspace.newId,
        queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
      ),
    );
    final environmentManagementController = EnvironmentManagementController(
      EnvironmentManagementDependencies(
        environmentStoreState: environmentStoreState,
        workspaceController: workspaceController,
        context: config.shell.context,
        mounted: config.shell.mounted,
        workspaces: config.workspace.workspaces,
        activeWorkspace: config.workspace.activeWorkspace,
        showMessage: config.shell.showMessage,
        navigation: environmentNavigationController,
        mutations: environmentManagementMutations,
      ),
    );
    final workspaceShortcutController = WorkspaceShortcutController(
      WorkspaceShortcutDependencies(
        appUiState: appUiState,
        workspaceLinksController: workspaceLinksController,
        focusedWindowOrNull: config.workspace.focusedWindowOrNull,
        showWorkspaceScreen: config.workspace.showWorkspaceScreen,
        toggleExpose: config.workspace.toggleExpose,
        toggleVideoPlayback: config.workspace.toggleVideoPlayback,
        navigation: environmentNavigationController,
      ),
    );
    final workspaceViewTrackingController = WorkspaceViewTrackingController(
      WorkspaceViewTrackingDependencies(
        environmentStoreState: environmentStoreState,
        appUiState: appUiState,
        workspaceViewTrackingState: workspaceViewTrackingState,
        mounted: config.shell.mounted,
        activeWorkspace: config.workspace.activeWorkspace,
        updateEnvironment: config.environment.updateEnvironment,
      ),
    );
    final environmentController = EnvironmentController(
      navigation: environmentNavigationController,
      management: environmentManagementController,
    );
    final workspaceVideoConversionController = WorkspaceVideoConversionController(
      showMessage: config.shell.showMessage,
      mediaInspector: foundation.mediaInspector,
      videoFrameExporter: videoFrameExporter,
      videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
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
      confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
      videoFrameExporter: videoFrameExporter,
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
      workspaceLinksLauncher: workspaceLinksLauncher,
      workspaceLinksPrompts: workspaceLinksPrompts,
      workspaceController: workspaceController,
      workspaceWindowController: workspaceWindowController,
      workspaceWindowHistoryController: workspaceWindowHistoryController,
      workspaceViewportSessionController: workspaceViewportSessionController,
      environmentController: environmentController,
      workspaceExposeLayoutController: workspaceExposeLayoutController,
      workspaceShortcutController: workspaceShortcutController,
      workspaceViewTrackingController: workspaceViewTrackingController,
      workspaceVideoConversionController: workspaceVideoConversionController,
    );
  }
}

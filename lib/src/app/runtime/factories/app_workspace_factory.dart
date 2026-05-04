import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_media_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_prompts.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_environment_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_expose_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_gesture_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

class WorkspaceDependencies {
  const WorkspaceDependencies({
    required this.platformBridge,
    required this.environmentStore,
    required this.mediaInspector,
    required this.appUiController,
    required this.isRunningInWidgetTest,
    required this.context,
    required this.mounted,
    required this.showMessage,
    required this.updateEnvironment,
    required this.replaceWorkspace,
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
    required this.environmentStoreState,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
    required this.environmentWindowHistoryState,
  });

  final PlatformBridge platformBridge;
  final EnvironmentStore environmentStore;
  final MediaInspector mediaInspector;
  final AppUiController appUiController;
  final bool isRunningInWidgetTest;
  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
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
  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final EnvironmentWindowHistoryState environmentWindowHistoryState;
}

class WorkspaceParts {
  const WorkspaceParts({
    required this.workspaceController,
    required this.environmentController,
    required this.environmentWindowHistoryController,
  });

  final WorkspaceController workspaceController;
  final EnvironmentController environmentController;
  final EnvironmentWindowHistoryController environmentWindowHistoryController;
}

ThumbnailController createThumbnailController({required WorkspaceDependencies dependencies}) {
  return ThumbnailController(
    state: dependencies.thumbnailRefreshState,
    refresher: ThumbnailRefresher(
      environmentStoreState: dependencies.environmentStoreState,
      updateEnvironment: dependencies.environmentStore.updateEnvironment,
      renderer: ThumbnailRenderer(isRunningInWidgetTest: dependencies.isRunningInWidgetTest),
      store: ThumbnailStore(thumbnailDirectory: dependencies.platformBridge.thumbnailDirectory),
    ),
    activeScreen: () => dependencies.appUiState.screen,
    activeWorkspaceId: () => dependencies.activeWorkspace()?.id,
    viewportSize: () => dependencies.workspaceViewportState.viewportSize,
  );
}

WorkspaceLinksController createWorkspaceLinksController({required WorkspaceDependencies dependencies}) {
  return WorkspaceLinksController(
    screen: () => dependencies.appUiState.screen,
    hasSession: () => dependencies.environmentStoreState.environment != null,
    activeWorkspace: dependencies.activeWorkspace,
    workspaces: dependencies.workspaces,
    replaceWorkspace: dependencies.replaceWorkspace,
    newId: dependencies.newId,
    showMessage: dependencies.showMessage,
    mounted: dependencies.mounted,
    context: dependencies.context,
  );
}

WorkspaceWindowController createWorkspaceWindowController({
  required WorkspaceDependencies dependencies,
  required WorkspaceGestureController gestureController,
  required WorkspaceWindowsController windowsController,
}) {
  return WorkspaceWindowController(
    appUiState: dependencies.appUiState,
    windowInteractionState: dependencies.windowInteractionState,
    activeWorkspace: () => dependencies.activeWorkspace()!,
    activeWorkspaceOrNull: dependencies.activeWorkspace,
    gestureController: gestureController,
    windowsController: windowsController,
  );
}

WorkspaceVideoConversionController createWorkspaceVideoConversionController({
  required WorkspaceDependencies dependencies,
  required VideoFrameExporter videoFrameExporter,
  required WorkspaceVideoConversionPrompts workspaceVideoConversionPrompts,
}) {
  return WorkspaceVideoConversionController(
    showMessage: dependencies.showMessage,
    mediaInspector: dependencies.mediaInspector,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: dependencies.platformBridge.createFileBookmark,
    activeWorkspace: dependencies.activeWorkspace,
    replaceWorkspace: dependencies.replaceWorkspace,
    colorFromDigest: dependencies.colorFromDigest,
    removePausedVideoWindow: dependencies.windowInteractionState.removePausedVideoWindow,
  );
}

WorkspaceMediaImportController createWorkspaceMediaImportController({
  required WorkspaceDependencies dependencies,
  required ThumbnailController thumbnailController,
  required VideoFrameExporter videoFrameExporter,
  required WorkspaceVideoConversionPrompts workspaceVideoConversionPrompts,
}) {
  return WorkspaceMediaImportController(
    imageExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'],
    videoExtensions: const ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'],
    environmentStoreState: dependencies.environmentStoreState,
    activeWorkspace: () => dependencies.activeWorkspace()!,
    confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
    videoFrameExporter: videoFrameExporter,
    createFileBookmark: dependencies.platformBridge.createFileBookmark,
    mediaInspector: dependencies.mediaInspector,
    updateEnvironment: dependencies.environmentStore.updateEnvironment,
    thumbnailController: thumbnailController,
    showMessage: dependencies.showMessage,
  );
}

EnvironmentNavigationController createEnvironmentNavigationController({
  required WorkspaceDependencies dependencies,
  required ThumbnailController thumbnailController,
  required WorkspaceExposeController exposeController,
}) {
  return EnvironmentNavigationController(
    EnvironmentNavigationDependencies(
      environmentStoreState: dependencies.environmentStoreState,
      appUiState: dependencies.appUiState,
      exposeController: exposeController,
      openWorkspaces: dependencies.openWorkspaces,
      updateEnvironment: dependencies.updateEnvironment,
      showWorkspaceScreen: dependencies.showWorkspaceScreen,
      showLibraryScreen: dependencies.showLibraryScreen,
      workspaceSwitchTarget: dependencies.appUiController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    ),
  );
}

WorkspaceExposeLayoutController createWorkspaceExposeLayoutController({
  required WorkspaceDependencies dependencies,
  required WorkspaceWindowController workspaceWindowController,
}) {
  return WorkspaceExposeLayoutController(
    WorkspaceExposeLayoutDependencies(
      appUiState: dependencies.appUiState,
      workspaceViewportState: dependencies.workspaceViewportState,
      context: dependencies.context,
      mounted: dependencies.mounted,
      activeWorkspace: dependencies.activeWorkspace,
      replaceWorkspace: dependencies.replaceWorkspace,
      showMessage: dependencies.showMessage,
      showWorkspaceScreen: dependencies.showWorkspaceScreen,
      windowController: workspaceWindowController,
    ),
  );
}

EnvironmentManagementMutations createEnvironmentManagementMutations({
  required WorkspaceDependencies dependencies,
  required ThumbnailController thumbnailController,
  required WorkspaceEnvironmentController environmentController,
  required WorkspaceExposeController exposeController,
}) {
  return EnvironmentManagementMutations(
    EnvironmentManagementMutationDependencies(
      environmentStoreState: dependencies.environmentStoreState,
      appUiState: dependencies.appUiState,
      tabsController: environmentController.tabs,
      windowTransferController: environmentController.windowTransfer,
      exposeController: exposeController,
      workspaces: dependencies.workspaces,
      updateEnvironment: dependencies.updateEnvironment,
      replaceWorkspace: dependencies.replaceWorkspace,
      showWorkspaceScreen: dependencies.showWorkspaceScreen,
      newId: dependencies.newId,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
    ),
  );
}

EnvironmentManagementController createEnvironmentManagementController({
  required WorkspaceDependencies dependencies,
  required EnvironmentNavigationController navigationController,
  required ThumbnailController thumbnailController,
  required WorkspaceEnvironmentController environmentController,
  required WorkspaceExposeController exposeController,
}) {
  final mutations = createEnvironmentManagementMutations(
    dependencies: dependencies,
    thumbnailController: thumbnailController,
    environmentController: environmentController,
    exposeController: exposeController,
  );

  return EnvironmentManagementController(
    EnvironmentManagementDependencies(
      environmentStoreState: dependencies.environmentStoreState,
      windowTransferController: environmentController.windowTransfer,
      exposeController: exposeController,
      context: dependencies.context,
      mounted: dependencies.mounted,
      workspaces: dependencies.workspaces,
      activeWorkspace: dependencies.activeWorkspace,
      showMessage: dependencies.showMessage,
      navigation: navigationController,
      mutations: mutations,
    ),
  );
}

WorkspaceShortcutController createWorkspaceShortcutController({
  required WorkspaceDependencies dependencies,
  required EnvironmentNavigationController navigationController,
  required WorkspaceLinksController workspaceLinksController,
}) {
  return WorkspaceShortcutController(
    WorkspaceShortcutDependencies(
      appUiState: dependencies.appUiState,
      workspaceLinksController: workspaceLinksController,
      focusedWindowOrNull: dependencies.focusedWindowOrNull,
      showWorkspaceScreen: dependencies.showWorkspaceScreen,
      toggleExpose: dependencies.toggleExpose,
      toggleVideoPlayback: dependencies.toggleVideoPlayback,
      navigation: navigationController,
    ),
  );
}

WorkspaceViewTrackingController createWorkspaceViewTrackingController({required WorkspaceDependencies dependencies}) {
  return WorkspaceViewTrackingController(
    WorkspaceViewTrackingDependencies(
      environmentStoreState: dependencies.environmentStoreState,
      appUiState: dependencies.appUiState,
      workspaceViewTrackingState: dependencies.workspaceViewTrackingState,
      mounted: dependencies.mounted,
      activeWorkspace: dependencies.activeWorkspace,
      updateEnvironment: dependencies.updateEnvironment,
    ),
  );
}

EnvironmentWindowHistoryController createEnvironmentWindowHistoryController({
  required WorkspaceDependencies dependencies,
  required WorkspaceExposeController exposeController,
  required WorkspaceWindowsController windowsController,
  required WorkspacePlaybackController playbackController,
}) {
  return EnvironmentWindowHistoryController(
    environment: () => dependencies.environmentStoreState.environment,
    workspaces: dependencies.workspaces,
    activeWorkspace: dependencies.activeWorkspace,
    environmentWindowHistoryState: dependencies.environmentWindowHistoryState,
    exposeController: exposeController,
    windowsController: windowsController,
    playbackController: playbackController,
    updateEnvironment: dependencies.environmentStore.updateEnvironment,
    replaceWorkspace: dependencies.environmentStore.replaceWorkspace,
    showMessage: dependencies.showMessage,
    showWorkspaceScreen: dependencies.showWorkspaceScreen,
    screen: () => dependencies.appUiState.screen,
    maxRecentlyClosedWindows: 12,
  );
}

WorkspaceController createWorkspaceController({
  required WorkspaceGestureController gesture,
  required WorkspaceExposeController expose,
  required WorkspaceWindowsController windows,
  required WorkspaceViewportController viewport,
  required WorkspacePlaybackController playback,
  required WorkspaceEnvironmentController environment,
  required WorkspaceWindowController window,
  required WorkspaceMediaController media,
  required WorkspaceExposeLayoutController layout,
  required WorkspaceShortcutController shortcuts,
  required WorkspaceLinksController links,
  required ThumbnailController thumbnails,
  required WorkspaceViewTrackingController tracking,
}) {
  return WorkspaceController(
    gesture: gesture,
    expose: expose,
    windows: windows,
    viewport: viewport,
    playback: playback,
    environment: environment,
    window: window,
    media: media,
    layout: layout,
    shortcuts: shortcuts,
    links: links,
    thumbnails: thumbnails,
    tracking: tracking,
  );
}

WorkspaceParts assembleWorkspace({required WorkspaceDependencies dependencies}) {
  final thumbnails = createThumbnailController(dependencies: dependencies);
  final links = createWorkspaceLinksController(dependencies: dependencies);

  final gesture = WorkspaceGestureController(windowInteractionState: dependencies.windowInteractionState);
  final expose = WorkspaceExposeController(windowInteractionState: dependencies.windowInteractionState);
  final windows = WorkspaceWindowsController(
    appUiState: dependencies.appUiState,
    windowInteractionState: dependencies.windowInteractionState,
    replaceWorkspace: dependencies.replaceWorkspace,
  );
  final viewport = WorkspaceViewportController(
    environmentStoreState: dependencies.environmentStoreState,
    appUiState: dependencies.appUiState,
    windowInteractionState: dependencies.windowInteractionState,
    workspaceViewportState: dependencies.workspaceViewportState,
    thumbnailController: thumbnails,
    replaceWorkspace: dependencies.replaceWorkspace,
    activeWorkspaceOrNull: dependencies.activeWorkspace,
    applyWorkspaceViewport: dependencies.setWorkspaceViewport,
    refreshActiveWorkspaceThumbnail: thumbnails.refreshActiveWorkspaceIfNeeded,
  );
  final playback = WorkspacePlaybackController(
    windowInteractionState: dependencies.windowInteractionState,
    replaceWorkspace: dependencies.replaceWorkspace,
    environment: () => dependencies.environmentStoreState.environment,
    activeWorkspaceOrNull: dependencies.activeWorkspace,
  );
  final workspaceEnvironment = WorkspaceEnvironmentController();

  final window = createWorkspaceWindowController(
    dependencies: dependencies,
    gestureController: gesture,
    windowsController: windows,
  );

  final videoFrameExporter = VideoFrameExporter(mediaInspector: dependencies.mediaInspector);
  final videoConversionPrompts = WorkspaceVideoConversionPrompts(context: dependencies.context);
  final videoConversion = createWorkspaceVideoConversionController(
    dependencies: dependencies,
    videoFrameExporter: videoFrameExporter,
    workspaceVideoConversionPrompts: videoConversionPrompts,
  );
  final mediaImport = createWorkspaceMediaImportController(
    dependencies: dependencies,
    thumbnailController: thumbnails,
    videoFrameExporter: videoFrameExporter,
    workspaceVideoConversionPrompts: videoConversionPrompts,
  );
  final media = WorkspaceMediaController(importController: mediaImport, videoConversionController: videoConversion);

  final navigation = createEnvironmentNavigationController(
    dependencies: dependencies,
    thumbnailController: thumbnails,
    exposeController: expose,
  );
  final layout = createWorkspaceExposeLayoutController(dependencies: dependencies, workspaceWindowController: window);
  final management = createEnvironmentManagementController(
    dependencies: dependencies,
    navigationController: navigation,
    thumbnailController: thumbnails,
    environmentController: workspaceEnvironment,
    exposeController: expose,
  );
  final environment = EnvironmentController(navigation: navigation, management: management);
  final shortcuts = createWorkspaceShortcutController(
    dependencies: dependencies,
    navigationController: navigation,
    workspaceLinksController: links,
  );
  final tracking = createWorkspaceViewTrackingController(dependencies: dependencies);
  final environmentHistory = createEnvironmentWindowHistoryController(
    dependencies: dependencies,
    exposeController: expose,
    windowsController: windows,
    playbackController: playback,
  );

  final workspace = createWorkspaceController(
    gesture: gesture,
    expose: expose,
    windows: windows,
    viewport: viewport,
    playback: playback,
    environment: workspaceEnvironment,
    window: window,
    media: media,
    layout: layout,
    shortcuts: shortcuts,
    links: links,
    thumbnails: thumbnails,
    tracking: tracking,
  );

  return WorkspaceParts(
    workspaceController: workspace,
    environmentController: environment,
    environmentWindowHistoryController: environmentHistory,
  );
}

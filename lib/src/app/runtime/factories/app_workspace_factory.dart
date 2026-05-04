import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_root.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
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
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';

class WorkspaceServices {
  const WorkspaceServices({
    required this.platformBridge,
    required this.environmentStore,
    required this.mediaInspector,
    required this.appUiController,
  });

  final PlatformBridge platformBridge;
  final EnvironmentStore environmentStore;
  final MediaInspector mediaInspector;
  final AppUiController appUiController;
}

class WorkspaceRuntime {
  const WorkspaceRuntime({
    required this.isRunningInWidgetTest,
    required this.context,
    required this.mounted,
    required this.showMessage,
  });

  final bool isRunningInWidgetTest;
  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
}

class WorkspaceQueries {
  const WorkspaceQueries({
    required this.activeWorkspace,
    required this.workspaces,
    required this.openWorkspaces,
    required this.focusedWindowOrNull,
  });

  final Workspace? Function() activeWorkspace;
  final List<Workspace> Function() workspaces;
  final List<Workspace> Function() openWorkspaces;
  final Window? Function() focusedWindowOrNull;
}

class WorkspaceDependencies {
  const WorkspaceDependencies({
    required this.rootObjects,
    required this.services,
    required this.runtime,
    required this.queries,
  });

  final AppRootObjects rootObjects;
  final WorkspaceServices services;
  final WorkspaceRuntime runtime;
  final WorkspaceQueries queries;
}

class WorkspaceParts {
  const WorkspaceParts({required this.workspaceController, required this.environmentController});

  final WorkspaceController workspaceController;
  final EnvironmentController environmentController;
}

ThumbnailController createThumbnailController({required WorkspaceDependencies dependencies}) {
  return ThumbnailController(
    state: dependencies.rootObjects.thumbnailRefreshState,
    refresher: ThumbnailRefresher(
      environmentStoreState: dependencies.services.environmentStore.environmentStoreState,
      updateEnvironment: dependencies.services.environmentStore.updateEnvironment,
      renderer: ThumbnailRenderer(isRunningInWidgetTest: dependencies.runtime.isRunningInWidgetTest),
      store: ThumbnailStore(thumbnailDirectory: dependencies.services.platformBridge.thumbnailDirectory),
    ),
    activeScreen: () => dependencies.rootObjects.appUiState.screen,
    activeWorkspaceId: () => dependencies.queries.activeWorkspace()?.id,
    viewportSize: () => dependencies.rootObjects.workspaceViewportState.viewportSize,
  );
}

WorkspaceLinksController createWorkspaceLinksController({required WorkspaceDependencies dependencies}) {
  return WorkspaceLinksController(
    screen: () => dependencies.rootObjects.appUiState.screen,
    hasSession: () => dependencies.services.environmentStore.environmentStoreState.environment != null,
    activeWorkspace: dependencies.queries.activeWorkspace,
    workspaces: dependencies.queries.workspaces,
    replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
    newId: newSerenityId,
    showMessage: dependencies.runtime.showMessage,
    mounted: dependencies.runtime.mounted,
    context: dependencies.runtime.context,
  );
}

WorkspaceWindowController createWorkspaceWindowController({
  required WorkspaceDependencies dependencies,
  required WorkspaceGestureController gestureController,
  required WorkspaceWindowsController windowsController,
}) {
  return WorkspaceWindowController(
    appUiState: dependencies.rootObjects.appUiState,
    windowInteractionState: dependencies.rootObjects.windowInteractionState,
    activeWorkspace: () => dependencies.queries.activeWorkspace()!,
    activeWorkspaceOrNull: dependencies.queries.activeWorkspace,
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
    showMessage: dependencies.runtime.showMessage,
    mediaInspector: dependencies.services.mediaInspector,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: dependencies.services.platformBridge.createFileBookmark,
    activeWorkspace: dependencies.queries.activeWorkspace,
    replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
    colorFromDigest: assetColorValueFromDigest,
    removePausedVideoWindow: dependencies.rootObjects.windowInteractionState.removePausedVideoWindow,
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
    appUiState: dependencies.rootObjects.appUiState,
    environmentStoreState: dependencies.services.environmentStore.environmentStoreState,
    activeWorkspace: () => dependencies.queries.activeWorkspace()!,
    confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
    videoFrameExporter: videoFrameExporter,
    createFileBookmark: dependencies.services.platformBridge.createFileBookmark,
    mediaInspector: dependencies.services.mediaInspector,
    updateEnvironment: dependencies.services.environmentStore.updateEnvironment,
    thumbnailController: thumbnailController,
    showMessage: dependencies.runtime.showMessage,
  );
}

EnvironmentNavigationController createEnvironmentNavigationController({
  required WorkspaceDependencies dependencies,
  required ThumbnailController thumbnailController,
  required WorkspaceExposeController exposeController,
}) {
  final appUiController = dependencies.services.appUiController;

  return EnvironmentNavigationController(
    EnvironmentNavigationDependencies(
      environmentStoreState: dependencies.services.environmentStore.environmentStoreState,
      appUiState: dependencies.rootObjects.appUiState,
      exposeController: exposeController,
      openWorkspaces: dependencies.queries.openWorkspaces,
      updateEnvironment: dependencies.services.environmentStore.updateEnvironment,
      showWorkspaceScreen:
          ({
            WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
            bool resetEditMode = true,
            bool clearExposeSelection = true,
            bool refreshWorkspaceTracking = true,
          }) => appUiController.showWorkspaceScreen(
            workspaceLayoutMode: workspaceLayoutMode,
            resetEditMode: resetEditMode,
            clearExposeSelection: clearExposeSelection,
            refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
          ),
      showLibraryScreen:
          ({bool resetEditMode = true, bool clearExposeSelection = true, bool refreshWorkspaceTracking = true}) =>
              appUiController.showLibraryScreen(
                resetEditMode: resetEditMode,
                clearExposeSelection: clearExposeSelection,
                refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
              ),
      workspaceSwitchTarget: dependencies.services.appUiController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    ),
  );
}

WorkspaceExposeLayoutController createWorkspaceExposeLayoutController({
  required WorkspaceDependencies dependencies,
  required WorkspaceWindowController workspaceWindowController,
}) {
  final appUiController = dependencies.services.appUiController;

  return WorkspaceExposeLayoutController(
    WorkspaceExposeLayoutDependencies(
      appUiState: dependencies.rootObjects.appUiState,
      workspaceViewportState: dependencies.rootObjects.workspaceViewportState,
      context: dependencies.runtime.context,
      mounted: dependencies.runtime.mounted,
      activeWorkspace: dependencies.queries.activeWorkspace,
      replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
      showMessage: dependencies.runtime.showMessage,
      showWorkspaceScreen:
          ({
            WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
            bool resetEditMode = true,
            bool clearExposeSelection = true,
            bool refreshWorkspaceTracking = true,
          }) => appUiController.showWorkspaceScreen(
            workspaceLayoutMode: workspaceLayoutMode,
            resetEditMode: resetEditMode,
            clearExposeSelection: clearExposeSelection,
            refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
          ),
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
  final appUiController = dependencies.services.appUiController;

  return EnvironmentManagementMutations(
    EnvironmentManagementMutationDependencies(
      environmentStoreState: dependencies.services.environmentStore.environmentStoreState,
      appUiState: dependencies.rootObjects.appUiState,
      tabsController: environmentController.tabs,
      windowTransferController: environmentController.windowTransfer,
      exposeController: exposeController,
      workspaces: dependencies.queries.workspaces,
      updateEnvironment: dependencies.services.environmentStore.updateEnvironment,
      replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
      showWorkspaceScreen:
          ({
            WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
            bool resetEditMode = true,
            bool clearExposeSelection = true,
            bool refreshWorkspaceTracking = true,
          }) => appUiController.showWorkspaceScreen(
            workspaceLayoutMode: workspaceLayoutMode,
            resetEditMode: resetEditMode,
            clearExposeSelection: clearExposeSelection,
            refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
          ),
      newId: newSerenityId,
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
      environmentStoreState: dependencies.services.environmentStore.environmentStoreState,
      windowTransferController: environmentController.windowTransfer,
      exposeController: exposeController,
      context: dependencies.runtime.context,
      mounted: dependencies.runtime.mounted,
      workspaces: dependencies.queries.workspaces,
      activeWorkspace: dependencies.queries.activeWorkspace,
      showMessage: dependencies.runtime.showMessage,
      navigation: navigationController,
      mutations: mutations,
    ),
  );
}

WorkspaceShortcutController createWorkspaceShortcutController({
  required WorkspaceDependencies dependencies,
  required EnvironmentManagementController managementController,
  required EnvironmentNavigationController navigationController,
  required WorkspacePlaybackController playbackController,
  required WorkspaceLinksController workspaceLinksController,
}) {
  final appUiController = dependencies.services.appUiController;

  return WorkspaceShortcutController(
    WorkspaceShortcutDependencies(
      appUiState: dependencies.rootObjects.appUiState,
      appUiController: appUiController,
      playbackController: playbackController,
      workspaceLinksController: workspaceLinksController,
      focusedWindowOrNull: dependencies.queries.focusedWindowOrNull,
      activeWorkspaceId: () =>
          dependencies.services.environmentStore.environmentStoreState.environment?.activeWorkspaceId,
      showWorkspaceScreen:
          ({
            WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
            bool resetEditMode = true,
            bool clearExposeSelection = true,
            bool refreshWorkspaceTracking = true,
          }) => appUiController.showWorkspaceScreen(
            workspaceLayoutMode: workspaceLayoutMode,
            resetEditMode: resetEditMode,
            clearExposeSelection: clearExposeSelection,
            refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
          ),
      management: managementController,
      navigation: navigationController,
    ),
  );
}

WorkspaceViewTrackingController createWorkspaceViewTrackingController({required WorkspaceDependencies dependencies}) {
  return WorkspaceViewTrackingController(
    WorkspaceViewTrackingDependencies(
      environmentStoreState: dependencies.services.environmentStore.environmentStoreState,
      appUiState: dependencies.rootObjects.appUiState,
      workspaceViewTrackingState: dependencies.rootObjects.workspaceViewTrackingState,
      mounted: dependencies.runtime.mounted,
      activeWorkspace: dependencies.queries.activeWorkspace,
      updateEnvironment: dependencies.services.environmentStore.updateEnvironment,
    ),
  );
}

EnvironmentWindowHistoryController createEnvironmentWindowHistoryController({
  required WorkspaceDependencies dependencies,
  required WorkspaceExposeController exposeController,
  required WorkspaceWindowsController windowsController,
  required WorkspacePlaybackController playbackController,
}) {
  final appUiController = dependencies.services.appUiController;

  return EnvironmentWindowHistoryController(
    environment: () => dependencies.services.environmentStore.environmentStoreState.environment,
    workspaces: dependencies.queries.workspaces,
    activeWorkspace: dependencies.queries.activeWorkspace,
    environmentWindowHistoryState: dependencies.rootObjects.environmentWindowHistoryState,
    exposeController: exposeController,
    windowsController: windowsController,
    playbackController: playbackController,
    updateEnvironment: dependencies.services.environmentStore.updateEnvironment,
    replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
    showMessage: dependencies.runtime.showMessage,
    showWorkspaceScreen:
        ({
          WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
          bool resetEditMode = true,
          bool clearExposeSelection = true,
          bool refreshWorkspaceTracking = true,
        }) => appUiController.showWorkspaceScreen(
          workspaceLayoutMode: workspaceLayoutMode,
          resetEditMode: resetEditMode,
          clearExposeSelection: clearExposeSelection,
          refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
        ),
    screen: () => dependencies.rootObjects.appUiState.screen,
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

  final gesture = WorkspaceGestureController(windowInteractionState: dependencies.rootObjects.windowInteractionState);
  final expose = WorkspaceExposeController(windowInteractionState: dependencies.rootObjects.windowInteractionState);
  final windows = WorkspaceWindowsController(
    appUiState: dependencies.rootObjects.appUiState,
    windowInteractionState: dependencies.rootObjects.windowInteractionState,
    replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
  );
  final viewport = WorkspaceViewportController(
    environmentStoreState: dependencies.services.environmentStore.environmentStoreState,
    appUiState: dependencies.rootObjects.appUiState,
    windowInteractionState: dependencies.rootObjects.windowInteractionState,
    workspaceViewportState: dependencies.rootObjects.workspaceViewportState,
    thumbnailController: thumbnails,
    replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
    activeWorkspaceOrNull: dependencies.queries.activeWorkspace,
    refreshActiveWorkspaceThumbnail: thumbnails.refreshActiveWorkspaceIfNeeded,
  );
  final playback = WorkspacePlaybackController(
    windowInteractionState: dependencies.rootObjects.windowInteractionState,
    replaceWorkspace: dependencies.services.environmentStore.replaceWorkspace,
    environment: () => dependencies.services.environmentStore.environmentStoreState.environment,
    activeWorkspaceOrNull: dependencies.queries.activeWorkspace,
  );
  final workspaceEnvironment = WorkspaceEnvironmentController();

  final window = createWorkspaceWindowController(
    dependencies: dependencies,
    gestureController: gesture,
    windowsController: windows,
  );

  final videoFrameExporter = VideoFrameExporter(mediaInspector: dependencies.services.mediaInspector);
  final videoConversionPrompts = WorkspaceVideoConversionPrompts(context: dependencies.runtime.context);
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
  final environmentHistory = createEnvironmentWindowHistoryController(
    dependencies: dependencies,
    exposeController: expose,
    windowsController: windows,
    playbackController: playback,
  );
  final environment = EnvironmentController(
    navigation: navigation,
    management: management,
    history: environmentHistory,
  );
  final shortcuts = createWorkspaceShortcutController(
    dependencies: dependencies,
    managementController: management,
    navigationController: navigation,
    playbackController: playback,
    workspaceLinksController: links,
  );
  final tracking = createWorkspaceViewTrackingController(dependencies: dependencies);

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

  return WorkspaceParts(workspaceController: workspace, environmentController: environment);
}

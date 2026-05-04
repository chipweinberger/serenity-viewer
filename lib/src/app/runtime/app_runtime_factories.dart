import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_prompts.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';

AppFoundation createAppFoundation({
  required AppRuntimeInputs inputs,
  required Future<void> Function() refreshWorkspaceTracking,
  required void Function(String workspaceId) markWorkspaceThumbnailDirty,
  required Future<void> Function() syncWindowTitle,
}) {
  final stateStore = inputs.stateStore;
  final environmentStoreState = stateStore.environmentStoreState;
  final appUiState = stateStore.appUiState;
  final windowInteractionState = stateStore.windowInteractionState;

  final appUiController = AppUiController(
    appUiState: appUiState,
    windowInteractionState: windowInteractionState,
    commitStateChange: inputs.app.commitStateChange,
    refreshWorkspaceTracking: refreshWorkspaceTracking,
  );
  final mediaInspector = MediaInspector(isRunningInWidgetTest: inputs.isRunningInWidgetTest);
  final platformBridge = PlatformBridge(
    environmentStoreState: environmentStoreState,
    isRunningInWidgetTest: inputs.isRunningInWidgetTest,
    windowTitle: inputs.app.windowTitle,
    showMessage: inputs.app.showMessage,
    isMounted: inputs.app.mounted,
  );
  final environmentStore = EnvironmentStore(
    environmentStoreState: environmentStoreState,
    appUiState: appUiState,
    markWorkspaceThumbnailDirty: markWorkspaceThumbnailDirty,
    commitStateChange: inputs.app.commitStateChange,
    refreshWorkspaceTracking: refreshWorkspaceTracking,
    syncWindowTitle: syncWindowTitle,
  );
  final environmentBookmarkSynchronizer = EnvironmentBookmarkSynchronizer(
    createFileBookmark: platformBridge.createFileBookmark,
  );

  return AppFoundation(
    appUiController: appUiController,
    mediaInspector: mediaInspector,
    platformBridge: platformBridge,
    sharedVideoControllerPool: SharedVideoControllerPool(),
    environmentStore: environmentStore,
    environmentBookmarkSynchronizer: environmentBookmarkSynchronizer,
  );
}

AppDocument createAppDocument({
  required AppRuntimeInputs inputs,
  required AppFoundation foundation,
  required AppWorkspaceServices workspace,
}) {
  final documentCoordinator = DocumentCoordinator(
    environmentStoreState: inputs.stateStore.environmentStoreState,
    environmentStore: foundation.environmentStore,
    context: inputs.app.context,
    mounted: inputs.app.mounted,
    seedEnvironment: inputs.environment.seedEnvironment,
    showMessage: inputs.app.showMessage,
    refreshActiveWorkspaceThumbnailIfNeeded: workspace.thumbnailController.refreshActiveWorkspaceIfNeeded,
    storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
    syncWindowTitle: foundation.platformBridge.syncWindowTitle,
    resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
    createFileBookmark: foundation.platformBridge.createFileBookmark,
    thumbnailDirectory: foundation.platformBridge.thumbnailDirectory,
    updateEnvironment: inputs.environment.updateEnvironment,
    saveEnvironment: inputs.environment.saveEnvironment,
  );

  return AppDocument(documentCoordinator: documentCoordinator);
}

ThumbnailController _createThumbnailController({
  required AppRuntimeInputs inputs,
  required AppFoundation foundation,
  required environmentStoreState,
  required appUiState,
  required workspaceViewportState,
  required thumbnailRefreshState,
}) {
  return ThumbnailController(
    state: thumbnailRefreshState,
    refresher: ThumbnailRefresher(
      environmentStoreState: environmentStoreState,
      updateEnvironment: foundation.environmentStore.updateEnvironment,
      renderer: ThumbnailRenderer(isRunningInWidgetTest: inputs.isRunningInWidgetTest),
      store: ThumbnailStore(thumbnailDirectory: foundation.platformBridge.thumbnailDirectory),
    ),
    activeScreen: () => appUiState.screen,
    activeWorkspaceId: () => inputs.workspace.activeWorkspace()?.id,
    viewportSize: () => workspaceViewportState.viewportSize,
    commitStateChange: inputs.app.commitStateChange,
    isMounted: inputs.app.mounted,
  );
}

({WorkspaceLinksController controller, WorkspaceLinksLauncher launcher, WorkspaceLinksPrompts prompts})
_createWorkspaceLinkServices({required AppRuntimeInputs inputs, required appUiState, required environmentStoreState}) {
  return (
    controller: WorkspaceLinksController(
      screen: () => appUiState.screen,
      hasSession: () => environmentStoreState.environment != null,
      activeWorkspace: inputs.workspace.activeWorkspace,
      workspaces: inputs.workspace.workspaces,
      replaceWorkspace: inputs.environment.replaceWorkspace,
      newId: inputs.workspace.newId,
      showMessage: inputs.app.showMessage,
    ),
    launcher: WorkspaceLinksLauncher(showMessage: inputs.app.showMessage, mounted: inputs.app.mounted),
    prompts: WorkspaceLinksPrompts(context: inputs.app.context),
  );
}

({
  WorkspaceController workspaceController,
  WorkspaceWindowController workspaceWindowController,
  WorkspaceWindowHistoryController workspaceWindowHistoryController,
  WorkspaceViewportSessionController workspaceViewportSessionController,
})
_createWorkspaceControllers({
  required AppRuntimeInputs inputs,
  required AppFoundation foundation,
  required ThumbnailController thumbnailController,
  required stateStore,
  required environmentStoreState,
  required appUiState,
  required windowInteractionState,
  required workspaceViewportState,
}) {
  final workspaceController = WorkspaceController(
    appUiState: appUiState,
    windowInteractionState: windowInteractionState,
    workspaceViewportState: workspaceViewportState,
    commitInteractionState: inputs.app.commitStateChange,
    replaceWorkspace: inputs.environment.replaceWorkspace,
    setWorkspaceViewport: inputs.workspace.setWorkspaceViewport,
    refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
  );
  final workspaceWindowController = WorkspaceWindowController(
    appUiState: appUiState,
    environment: () => environmentStoreState.environment,
    activeWorkspace: () => inputs.workspace.activeWorkspace()!,
    activeWorkspaceOrNull: inputs.workspace.activeWorkspace,
    workspaceController: workspaceController,
  );
  final workspaceWindowHistoryController = WorkspaceWindowHistoryController(
    environment: () => environmentStoreState.environment,
    workspaces: inputs.workspace.workspaces,
    activeWorkspace: inputs.workspace.activeWorkspace,
    workspaceWindowHistoryState: stateStore.workspaceWindowHistoryState,
    workspaceController: workspaceController,
    updateEnvironment: foundation.environmentStore.updateEnvironment,
    replaceWorkspace: foundation.environmentStore.replaceWorkspace,
    commitStateChange: inputs.app.commitStateChange,
    showMessage: inputs.app.showMessage,
    showWorkspaceScreen: inputs.workspace.showWorkspaceScreen,
    screen: () => appUiState.screen,
    maxRecentlyClosedWindows: 12,
  );
  final workspaceViewportSessionController = WorkspaceViewportSessionController(
    environmentStoreState: environmentStoreState,
    workspaceViewportState: workspaceViewportState,
    thumbnailController: thumbnailController,
    replaceWorkspace: foundation.environmentStore.replaceWorkspace,
  );

  return (
    workspaceController: workspaceController,
    workspaceWindowController: workspaceWindowController,
    workspaceWindowHistoryController: workspaceWindowHistoryController,
    workspaceViewportSessionController: workspaceViewportSessionController,
  );
}

({
  EnvironmentNavigationController navigationController,
  EnvironmentManagementController managementController,
  EnvironmentController environmentController,
  WorkspaceExposeLayoutController workspaceExposeLayoutController,
  WorkspaceShortcutController workspaceShortcutController,
  WorkspaceViewTrackingController workspaceViewTrackingController,
})
_createEnvironmentAndWorkspaceFlows({
  required AppRuntimeInputs inputs,
  required AppFoundation foundation,
  required ThumbnailController thumbnailController,
  required WorkspaceLinksController workspaceLinksController,
  required WorkspaceController workspaceController,
  required environmentStoreState,
  required appUiState,
  required workspaceViewTrackingState,
  required workspaceViewportState,
}) {
  final navigationController = EnvironmentNavigationController(
    EnvironmentNavigationDependencies(
      environmentStoreState: environmentStoreState,
      appUiState: appUiState,
      workspaceController: workspaceController,
      openWorkspaces: inputs.workspace.openWorkspaces,
      updateEnvironment: inputs.environment.updateEnvironment,
      showWorkspaceScreen: inputs.workspace.showWorkspaceScreen,
      showLibraryScreen: inputs.workspace.showLibraryScreen,
      workspaceSwitchTarget: foundation.appUiController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    ),
  );
  final workspaceExposeLayoutController = WorkspaceExposeLayoutController(
    WorkspaceExposeLayoutDependencies(
      appUiState: appUiState,
      workspaceViewportState: workspaceViewportState,
      context: inputs.app.context,
      mounted: inputs.app.mounted,
      activeWorkspace: inputs.workspace.activeWorkspace,
      replaceWorkspace: inputs.environment.replaceWorkspace,
      showWorkspaceScreen: inputs.workspace.showWorkspaceScreen,
    ),
  );
  final environmentManagementMutations = EnvironmentManagementMutations(
    EnvironmentManagementMutationDependencies(
      environmentStoreState: environmentStoreState,
      appUiState: appUiState,
      workspaceController: workspaceController,
      workspaces: inputs.workspace.workspaces,
      updateEnvironment: inputs.environment.updateEnvironment,
      replaceWorkspace: inputs.environment.replaceWorkspace,
      showWorkspaceScreen: inputs.workspace.showWorkspaceScreen,
      newId: inputs.workspace.newId,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
    ),
  );
  final managementController = EnvironmentManagementController(
    EnvironmentManagementDependencies(
      environmentStoreState: environmentStoreState,
      workspaceController: workspaceController,
      context: inputs.app.context,
      mounted: inputs.app.mounted,
      workspaces: inputs.workspace.workspaces,
      activeWorkspace: inputs.workspace.activeWorkspace,
      showMessage: inputs.app.showMessage,
      navigation: navigationController,
      mutations: environmentManagementMutations,
    ),
  );
  final workspaceShortcutController = WorkspaceShortcutController(
    WorkspaceShortcutDependencies(
      appUiState: appUiState,
      workspaceLinksController: workspaceLinksController,
      focusedWindowOrNull: inputs.workspace.focusedWindowOrNull,
      showWorkspaceScreen: inputs.workspace.showWorkspaceScreen,
      toggleExpose: inputs.workspace.toggleExpose,
      toggleVideoPlayback: inputs.workspace.toggleVideoPlayback,
      navigation: navigationController,
    ),
  );
  final workspaceViewTrackingController = WorkspaceViewTrackingController(
    WorkspaceViewTrackingDependencies(
      environmentStoreState: environmentStoreState,
      appUiState: appUiState,
      workspaceViewTrackingState: workspaceViewTrackingState,
      mounted: inputs.app.mounted,
      activeWorkspace: inputs.workspace.activeWorkspace,
      updateEnvironment: inputs.environment.updateEnvironment,
    ),
  );

  return (
    navigationController: navigationController,
    managementController: managementController,
    environmentController: EnvironmentController(navigation: navigationController, management: managementController),
    workspaceExposeLayoutController: workspaceExposeLayoutController,
    workspaceShortcutController: workspaceShortcutController,
    workspaceViewTrackingController: workspaceViewTrackingController,
  );
}

({
  WorkspaceVideoConversionController workspaceVideoConversionController,
  WorkspaceMediaImportController workspaceMediaImportController,
})
_createMediaFlows({
  required AppRuntimeInputs inputs,
  required AppFoundation foundation,
  required ThumbnailController thumbnailController,
  required environmentStoreState,
  required windowInteractionState,
}) {
  final videoFrameExporter = VideoFrameExporter(mediaInspector: foundation.mediaInspector);
  final workspaceVideoConversionPrompts = WorkspaceVideoConversionPrompts(context: inputs.app.context);
  final workspaceVideoConversionController = WorkspaceVideoConversionController(
    showMessage: inputs.app.showMessage,
    mediaInspector: foundation.mediaInspector,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: foundation.platformBridge.createFileBookmark,
    activeWorkspace: inputs.workspace.activeWorkspace,
    replaceWorkspace: inputs.environment.replaceWorkspace,
    colorFromDigest: inputs.workspace.colorFromDigest,
    removePausedVideoWindow: (windowId) {
      inputs.app.commitStateChange(() {
        windowInteractionState.pausedVideoWindows.remove(windowId);
      });
    },
  );
  final workspaceMediaImportController = WorkspaceMediaImportController(
    imageExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'],
    videoExtensions: const ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'],
    environmentStoreState: environmentStoreState,
    activeWorkspace: () => inputs.workspace.activeWorkspace()!,
    confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
    videoFrameExporter: videoFrameExporter,
    createFileBookmark: foundation.platformBridge.createFileBookmark,
    mediaInspector: foundation.mediaInspector,
    updateEnvironment: foundation.environmentStore.updateEnvironment,
    thumbnailController: thumbnailController,
    showMessage: inputs.app.showMessage,
  );

  return (
    workspaceVideoConversionController: workspaceVideoConversionController,
    workspaceMediaImportController: workspaceMediaImportController,
  );
}

AppWorkspaceServices createAppWorkspaceServices({required AppRuntimeInputs inputs, required AppFoundation foundation}) {
  final stateStore = inputs.stateStore;
  final environmentStoreState = stateStore.environmentStoreState;
  final appUiState = stateStore.appUiState;
  final windowInteractionState = stateStore.windowInteractionState;
  final workspaceViewTrackingState = stateStore.workspaceViewTrackingState;
  final workspaceViewportState = stateStore.workspaceViewportState;
  final thumbnailRefreshState = stateStore.thumbnailRefreshState;

  final thumbnailController = _createThumbnailController(
    inputs: inputs,
    foundation: foundation,
    environmentStoreState: environmentStoreState,
    appUiState: appUiState,
    workspaceViewportState: workspaceViewportState,
    thumbnailRefreshState: thumbnailRefreshState,
  );
  final workspaceLinksServices = _createWorkspaceLinkServices(
    inputs: inputs,
    appUiState: appUiState,
    environmentStoreState: environmentStoreState,
  );
  final workspaceControllers = _createWorkspaceControllers(
    inputs: inputs,
    foundation: foundation,
    thumbnailController: thumbnailController,
    stateStore: stateStore,
    environmentStoreState: environmentStoreState,
    appUiState: appUiState,
    windowInteractionState: windowInteractionState,
    workspaceViewportState: workspaceViewportState,
  );
  final environmentAndWorkspaceFlows = _createEnvironmentAndWorkspaceFlows(
    inputs: inputs,
    foundation: foundation,
    thumbnailController: thumbnailController,
    workspaceLinksController: workspaceLinksServices.controller,
    workspaceController: workspaceControllers.workspaceController,
    environmentStoreState: environmentStoreState,
    appUiState: appUiState,
    workspaceViewTrackingState: workspaceViewTrackingState,
    workspaceViewportState: workspaceViewportState,
  );
  final mediaFlows = _createMediaFlows(
    inputs: inputs,
    foundation: foundation,
    thumbnailController: thumbnailController,
    environmentStoreState: environmentStoreState,
    windowInteractionState: windowInteractionState,
  );

  return AppWorkspaceServices(
    thumbnailController: thumbnailController,
    workspaceMediaImportController: mediaFlows.workspaceMediaImportController,
    workspaceLinksController: workspaceLinksServices.controller,
    workspaceLinksLauncher: workspaceLinksServices.launcher,
    workspaceLinksPrompts: workspaceLinksServices.prompts,
    workspaceController: workspaceControllers.workspaceController,
    workspaceWindowController: workspaceControllers.workspaceWindowController,
    workspaceWindowHistoryController: workspaceControllers.workspaceWindowHistoryController,
    workspaceViewportSessionController: workspaceControllers.workspaceViewportSessionController,
    environmentController: environmentAndWorkspaceFlows.environmentController,
    workspaceExposeLayoutController: environmentAndWorkspaceFlows.workspaceExposeLayoutController,
    workspaceShortcutController: environmentAndWorkspaceFlows.workspaceShortcutController,
    workspaceViewTrackingController: environmentAndWorkspaceFlows.workspaceViewTrackingController,
    workspaceVideoConversionController: mediaFlows.workspaceVideoConversionController,
  );
}

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
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';

class _WorkspaceFactoryState {
  const _WorkspaceFactoryState({
    required this.stateStore,
    required this.environmentStoreState,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
  });

  final AppStateStore stateStore;
  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
}

class _WorkspaceFactoryScope {
  const _WorkspaceFactoryScope({required this.inputs, required this.foundation, required this.state});

  final AppRuntimeInputs inputs;
  final AppFoundation foundation;
  final _WorkspaceFactoryState state;
}

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

ThumbnailController _createThumbnailController({required _WorkspaceFactoryScope scope}) {
  return ThumbnailController(
    state: scope.state.thumbnailRefreshState,
    refresher: ThumbnailRefresher(
      environmentStoreState: scope.state.environmentStoreState,
      updateEnvironment: scope.foundation.environmentStore.updateEnvironment,
      renderer: ThumbnailRenderer(isRunningInWidgetTest: scope.inputs.isRunningInWidgetTest),
      store: ThumbnailStore(thumbnailDirectory: scope.foundation.platformBridge.thumbnailDirectory),
    ),
    activeScreen: () => scope.state.appUiState.screen,
    activeWorkspaceId: () => scope.inputs.workspace.activeWorkspace()?.id,
    viewportSize: () => scope.state.workspaceViewportState.viewportSize,
    commitStateChange: scope.inputs.app.commitStateChange,
    isMounted: scope.inputs.app.mounted,
  );
}

({WorkspaceLinksController controller, WorkspaceLinksLauncher launcher, WorkspaceLinksPrompts prompts})
_createWorkspaceLinkServices({required _WorkspaceFactoryScope scope}) {
  return (
    controller: WorkspaceLinksController(
      screen: () => scope.state.appUiState.screen,
      hasSession: () => scope.state.environmentStoreState.environment != null,
      activeWorkspace: scope.inputs.workspace.activeWorkspace,
      workspaces: scope.inputs.workspace.workspaces,
      replaceWorkspace: scope.inputs.environment.replaceWorkspace,
      newId: scope.inputs.workspace.newId,
      showMessage: scope.inputs.app.showMessage,
    ),
    launcher: WorkspaceLinksLauncher(showMessage: scope.inputs.app.showMessage, mounted: scope.inputs.app.mounted),
    prompts: WorkspaceLinksPrompts(context: scope.inputs.app.context),
  );
}

({
  WorkspaceController workspaceController,
  WorkspaceWindowController workspaceWindowController,
  WorkspaceWindowHistoryController workspaceWindowHistoryController,
  WorkspaceViewportSessionController workspaceViewportSessionController,
})
_createWorkspaceControllers({required _WorkspaceFactoryScope scope, required ThumbnailController thumbnailController}) {
  final workspaceController = WorkspaceController(
    appUiState: scope.state.appUiState,
    windowInteractionState: scope.state.windowInteractionState,
    workspaceViewportState: scope.state.workspaceViewportState,
    commitInteractionState: scope.inputs.app.commitStateChange,
    replaceWorkspace: scope.inputs.environment.replaceWorkspace,
    setWorkspaceViewport: scope.inputs.workspace.setWorkspaceViewport,
    refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
  );
  final workspaceWindowController = WorkspaceWindowController(
    appUiState: scope.state.appUiState,
    environment: () => scope.state.environmentStoreState.environment,
    activeWorkspace: () => scope.inputs.workspace.activeWorkspace()!,
    activeWorkspaceOrNull: scope.inputs.workspace.activeWorkspace,
    workspaceController: workspaceController,
  );
  final workspaceWindowHistoryController = WorkspaceWindowHistoryController(
    environment: () => scope.state.environmentStoreState.environment,
    workspaces: scope.inputs.workspace.workspaces,
    activeWorkspace: scope.inputs.workspace.activeWorkspace,
    workspaceWindowHistoryState: scope.state.stateStore.workspaceWindowHistoryState,
    workspaceController: workspaceController,
    updateEnvironment: scope.foundation.environmentStore.updateEnvironment,
    replaceWorkspace: scope.foundation.environmentStore.replaceWorkspace,
    commitStateChange: scope.inputs.app.commitStateChange,
    showMessage: scope.inputs.app.showMessage,
    showWorkspaceScreen: scope.inputs.workspace.showWorkspaceScreen,
    screen: () => scope.state.appUiState.screen,
    maxRecentlyClosedWindows: 12,
  );
  final workspaceViewportSessionController = WorkspaceViewportSessionController(
    environmentStoreState: scope.state.environmentStoreState,
    workspaceViewportState: scope.state.workspaceViewportState,
    thumbnailController: thumbnailController,
    replaceWorkspace: scope.foundation.environmentStore.replaceWorkspace,
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
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required WorkspaceLinksController workspaceLinksController,
  required WorkspaceController workspaceController,
}) {
  final navigationController = EnvironmentNavigationController(
    EnvironmentNavigationDependencies(
      environmentStoreState: scope.state.environmentStoreState,
      appUiState: scope.state.appUiState,
      workspaceController: workspaceController,
      openWorkspaces: scope.inputs.workspace.openWorkspaces,
      updateEnvironment: scope.inputs.environment.updateEnvironment,
      showWorkspaceScreen: scope.inputs.workspace.showWorkspaceScreen,
      showLibraryScreen: scope.inputs.workspace.showLibraryScreen,
      workspaceSwitchTarget: scope.foundation.appUiController.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    ),
  );
  final workspaceExposeLayoutController = WorkspaceExposeLayoutController(
    WorkspaceExposeLayoutDependencies(
      appUiState: scope.state.appUiState,
      workspaceViewportState: scope.state.workspaceViewportState,
      context: scope.inputs.app.context,
      mounted: scope.inputs.app.mounted,
      activeWorkspace: scope.inputs.workspace.activeWorkspace,
      replaceWorkspace: scope.inputs.environment.replaceWorkspace,
      showWorkspaceScreen: scope.inputs.workspace.showWorkspaceScreen,
    ),
  );
  final environmentManagementMutations = EnvironmentManagementMutations(
    EnvironmentManagementMutationDependencies(
      environmentStoreState: scope.state.environmentStoreState,
      appUiState: scope.state.appUiState,
      workspaceController: workspaceController,
      workspaces: scope.inputs.workspace.workspaces,
      updateEnvironment: scope.inputs.environment.updateEnvironment,
      replaceWorkspace: scope.inputs.environment.replaceWorkspace,
      showWorkspaceScreen: scope.inputs.workspace.showWorkspaceScreen,
      newId: scope.inputs.workspace.newId,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
    ),
  );
  final managementController = EnvironmentManagementController(
    EnvironmentManagementDependencies(
      environmentStoreState: scope.state.environmentStoreState,
      workspaceController: workspaceController,
      context: scope.inputs.app.context,
      mounted: scope.inputs.app.mounted,
      workspaces: scope.inputs.workspace.workspaces,
      activeWorkspace: scope.inputs.workspace.activeWorkspace,
      showMessage: scope.inputs.app.showMessage,
      navigation: navigationController,
      mutations: environmentManagementMutations,
    ),
  );
  final workspaceShortcutController = WorkspaceShortcutController(
    WorkspaceShortcutDependencies(
      appUiState: scope.state.appUiState,
      workspaceLinksController: workspaceLinksController,
      focusedWindowOrNull: scope.inputs.workspace.focusedWindowOrNull,
      showWorkspaceScreen: scope.inputs.workspace.showWorkspaceScreen,
      toggleExpose: scope.inputs.workspace.toggleExpose,
      toggleVideoPlayback: scope.inputs.workspace.toggleVideoPlayback,
      navigation: navigationController,
    ),
  );
  final workspaceViewTrackingController = WorkspaceViewTrackingController(
    WorkspaceViewTrackingDependencies(
      environmentStoreState: scope.state.environmentStoreState,
      appUiState: scope.state.appUiState,
      workspaceViewTrackingState: scope.state.workspaceViewTrackingState,
      mounted: scope.inputs.app.mounted,
      activeWorkspace: scope.inputs.workspace.activeWorkspace,
      updateEnvironment: scope.inputs.environment.updateEnvironment,
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
_createMediaFlows({required _WorkspaceFactoryScope scope, required ThumbnailController thumbnailController}) {
  final videoFrameExporter = VideoFrameExporter(mediaInspector: scope.foundation.mediaInspector);
  final workspaceVideoConversionPrompts = WorkspaceVideoConversionPrompts(context: scope.inputs.app.context);
  final workspaceVideoConversionController = WorkspaceVideoConversionController(
    showMessage: scope.inputs.app.showMessage,
    mediaInspector: scope.foundation.mediaInspector,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: scope.foundation.platformBridge.createFileBookmark,
    activeWorkspace: scope.inputs.workspace.activeWorkspace,
    replaceWorkspace: scope.inputs.environment.replaceWorkspace,
    colorFromDigest: scope.inputs.workspace.colorFromDigest,
    removePausedVideoWindow: (windowId) {
      scope.inputs.app.commitStateChange(() {
        scope.state.windowInteractionState.pausedVideoWindows.remove(windowId);
      });
    },
  );
  final workspaceMediaImportController = WorkspaceMediaImportController(
    imageExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'],
    videoExtensions: const ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'],
    environmentStoreState: scope.state.environmentStoreState,
    activeWorkspace: () => scope.inputs.workspace.activeWorkspace()!,
    confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
    videoFrameExporter: videoFrameExporter,
    createFileBookmark: scope.foundation.platformBridge.createFileBookmark,
    mediaInspector: scope.foundation.mediaInspector,
    updateEnvironment: scope.foundation.environmentStore.updateEnvironment,
    thumbnailController: thumbnailController,
    showMessage: scope.inputs.app.showMessage,
  );

  return (
    workspaceVideoConversionController: workspaceVideoConversionController,
    workspaceMediaImportController: workspaceMediaImportController,
  );
}

AppWorkspaceServices createAppWorkspaceServices({required AppRuntimeInputs inputs, required AppFoundation foundation}) {
  final scope = _WorkspaceFactoryScope(
    inputs: inputs,
    foundation: foundation,
    state: _WorkspaceFactoryState(
      stateStore: inputs.stateStore,
      environmentStoreState: inputs.stateStore.environmentStoreState,
      appUiState: inputs.stateStore.appUiState,
      windowInteractionState: inputs.stateStore.windowInteractionState,
      workspaceViewTrackingState: inputs.stateStore.workspaceViewTrackingState,
      workspaceViewportState: inputs.stateStore.workspaceViewportState,
      thumbnailRefreshState: inputs.stateStore.thumbnailRefreshState,
    ),
  );

  final thumbnailController = _createThumbnailController(scope: scope);
  final workspaceLinksServices = _createWorkspaceLinkServices(scope: scope);
  final workspaceControllers = _createWorkspaceControllers(scope: scope, thumbnailController: thumbnailController);
  final environmentAndWorkspaceFlows = _createEnvironmentAndWorkspaceFlows(
    scope: scope,
    thumbnailController: thumbnailController,
    workspaceLinksController: workspaceLinksServices.controller,
    workspaceController: workspaceControllers.workspaceController,
  );
  final mediaFlows = _createMediaFlows(scope: scope, thumbnailController: thumbnailController);

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

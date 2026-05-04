import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/media/video/video_frame_exporter.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
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
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

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

  AppRuntimeAppInputs get app => inputs.app;
  AppRuntimeEnvironmentInputs get env => inputs.environment;
  AppRuntimeWorkspaceInputs get ws => inputs.workspace;
  PlatformBridge get platform => foundation.platformBridge;
  EnvironmentStore get store => foundation.environmentStore;
  MediaInspector get media => foundation.mediaInspector;
  AppUiController get ui => foundation.appUiController;
  EnvironmentStoreState get envState => state.environmentStoreState;
  AppUiState get uiState => state.appUiState;
  WindowInteractionState get interactionState => state.windowInteractionState;
  WorkspaceViewTrackingState get trackingState => state.workspaceViewTrackingState;
  WorkspaceViewportState get viewportState => state.workspaceViewportState;
  ThumbnailRefreshState get thumbState => state.thumbnailRefreshState;
}

class _WorkspaceLinkServices {
  const _WorkspaceLinkServices({required this.controller, required this.launcher, required this.prompts});

  final WorkspaceLinksController controller;
  final WorkspaceLinksLauncher launcher;
  final WorkspaceLinksPrompts prompts;
}

class _WorkspaceControllers {
  const _WorkspaceControllers({
    required this.workspaceController,
    required this.workspaceWindowController,
    required this.workspaceWindowHistoryController,
    required this.workspaceViewportSessionController,
  });

  final WorkspaceController workspaceController;
  final WorkspaceWindowController workspaceWindowController;
  final WorkspaceWindowHistoryController workspaceWindowHistoryController;
  final WorkspaceViewportSessionController workspaceViewportSessionController;
}

class _EnvironmentAndWorkspaceFlows {
  const _EnvironmentAndWorkspaceFlows({
    required this.navigationController,
    required this.managementController,
    required this.environmentController,
    required this.workspaceExposeLayoutController,
    required this.workspaceShortcutController,
    required this.workspaceViewTrackingController,
  });

  final EnvironmentNavigationController navigationController;
  final EnvironmentManagementController managementController;
  final EnvironmentController environmentController;
  final WorkspaceExposeLayoutController workspaceExposeLayoutController;
  final WorkspaceShortcutController workspaceShortcutController;
  final WorkspaceViewTrackingController workspaceViewTrackingController;
}

class _MediaFlows {
  const _MediaFlows({required this.workspaceVideoConversionController, required this.workspaceMediaImportController});

  final WorkspaceVideoConversionController workspaceVideoConversionController;
  final WorkspaceMediaImportController workspaceMediaImportController;
}

ThumbnailController _createThumbnailController({required _WorkspaceFactoryScope scope}) {
  return ThumbnailController(
    state: scope.thumbState,
    refresher: ThumbnailRefresher(
      environmentStoreState: scope.envState,
      updateEnvironment: scope.store.updateEnvironment,
      renderer: ThumbnailRenderer(isRunningInWidgetTest: scope.inputs.isRunningInWidgetTest),
      store: ThumbnailStore(thumbnailDirectory: scope.platform.thumbnailDirectory),
    ),
    activeScreen: () => scope.uiState.screen,
    activeWorkspaceId: () => scope.ws.activeWorkspace()?.id,
    viewportSize: () => scope.viewportState.viewportSize,
    commitStateChange: scope.app.commitStateChange,
    isMounted: scope.app.mounted,
  );
}

_WorkspaceLinkServices _createWorkspaceLinkServices({required _WorkspaceFactoryScope scope}) {
  return _WorkspaceLinkServices(
    controller: WorkspaceLinksController(
      screen: () => scope.uiState.screen,
      hasSession: () => scope.envState.environment != null,
      activeWorkspace: scope.ws.activeWorkspace,
      workspaces: scope.ws.workspaces,
      replaceWorkspace: scope.env.replaceWorkspace,
      newId: scope.ws.newId,
      showMessage: scope.app.showMessage,
    ),
    launcher: WorkspaceLinksLauncher(showMessage: scope.app.showMessage, mounted: scope.app.mounted),
    prompts: WorkspaceLinksPrompts(context: scope.app.context),
  );
}

_WorkspaceControllers _createWorkspaceControllers({
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
}) {
  final workspaceController = WorkspaceController(
    appUiState: scope.uiState,
    windowInteractionState: scope.interactionState,
    workspaceViewportState: scope.viewportState,
    commitInteractionState: scope.app.commitStateChange,
    replaceWorkspace: scope.env.replaceWorkspace,
    setWorkspaceViewport: scope.ws.setWorkspaceViewport,
    refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
  );
  final workspaceWindowController = WorkspaceWindowController(
    appUiState: scope.uiState,
    environment: () => scope.envState.environment,
    activeWorkspace: () => scope.ws.activeWorkspace()!,
    activeWorkspaceOrNull: scope.ws.activeWorkspace,
    workspaceController: workspaceController,
  );
  final workspaceWindowHistoryController = WorkspaceWindowHistoryController(
    environment: () => scope.envState.environment,
    workspaces: scope.ws.workspaces,
    activeWorkspace: scope.ws.activeWorkspace,
    workspaceWindowHistoryState: scope.state.stateStore.workspaceWindowHistoryState,
    workspaceController: workspaceController,
    updateEnvironment: scope.store.updateEnvironment,
    replaceWorkspace: scope.store.replaceWorkspace,
    commitStateChange: scope.app.commitStateChange,
    showMessage: scope.app.showMessage,
    showWorkspaceScreen: scope.ws.showWorkspaceScreen,
    screen: () => scope.uiState.screen,
    maxRecentlyClosedWindows: 12,
  );
  final workspaceViewportSessionController = WorkspaceViewportSessionController(
    environmentStoreState: scope.envState,
    workspaceViewportState: scope.viewportState,
    thumbnailController: thumbnailController,
    replaceWorkspace: scope.store.replaceWorkspace,
  );

  return _WorkspaceControllers(
    workspaceController: workspaceController,
    workspaceWindowController: workspaceWindowController,
    workspaceWindowHistoryController: workspaceWindowHistoryController,
    workspaceViewportSessionController: workspaceViewportSessionController,
  );
}

_EnvironmentAndWorkspaceFlows _createEnvironmentAndWorkspaceFlows({
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required WorkspaceLinksController workspaceLinksController,
  required WorkspaceController workspaceController,
}) {
  final navigationController = _createEnvironmentNavigationController(
    scope: scope,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );
  final workspaceExposeLayoutController = _createWorkspaceExposeLayoutController(scope: scope);
  final managementController = _createEnvironmentManagementController(
    scope: scope,
    navigationController: navigationController,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );
  final workspaceShortcutController = _createWorkspaceShortcutController(
    scope: scope,
    navigationController: navigationController,
    workspaceLinksController: workspaceLinksController,
  );
  final workspaceViewTrackingController = _createWorkspaceViewTrackingController(scope: scope);

  return _EnvironmentAndWorkspaceFlows(
    navigationController: navigationController,
    managementController: managementController,
    environmentController: EnvironmentController(navigation: navigationController, management: managementController),
    workspaceExposeLayoutController: workspaceExposeLayoutController,
    workspaceShortcutController: workspaceShortcutController,
    workspaceViewTrackingController: workspaceViewTrackingController,
  );
}

EnvironmentNavigationController _createEnvironmentNavigationController({
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required WorkspaceController workspaceController,
}) {
  return EnvironmentNavigationController(
    EnvironmentNavigationDependencies(
      environmentStoreState: scope.envState,
      appUiState: scope.uiState,
      workspaceController: workspaceController,
      openWorkspaces: scope.ws.openWorkspaces,
      updateEnvironment: scope.env.updateEnvironment,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
      showLibraryScreen: scope.ws.showLibraryScreen,
      workspaceSwitchTarget: scope.ui.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    ),
  );
}

WorkspaceExposeLayoutController _createWorkspaceExposeLayoutController({required _WorkspaceFactoryScope scope}) {
  return WorkspaceExposeLayoutController(
    WorkspaceExposeLayoutDependencies(
      appUiState: scope.uiState,
      workspaceViewportState: scope.viewportState,
      context: scope.app.context,
      mounted: scope.app.mounted,
      activeWorkspace: scope.ws.activeWorkspace,
      replaceWorkspace: scope.env.replaceWorkspace,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
    ),
  );
}

EnvironmentManagementMutations _createEnvironmentManagementMutations({
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required WorkspaceController workspaceController,
}) {
  return EnvironmentManagementMutations(
    EnvironmentManagementMutationDependencies(
      environmentStoreState: scope.envState,
      appUiState: scope.uiState,
      workspaceController: workspaceController,
      workspaces: scope.ws.workspaces,
      updateEnvironment: scope.env.updateEnvironment,
      replaceWorkspace: scope.env.replaceWorkspace,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
      newId: scope.ws.newId,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
    ),
  );
}

EnvironmentManagementController _createEnvironmentManagementController({
  required _WorkspaceFactoryScope scope,
  required EnvironmentNavigationController navigationController,
  required ThumbnailController thumbnailController,
  required WorkspaceController workspaceController,
}) {
  final mutations = _createEnvironmentManagementMutations(
    scope: scope,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );

  return EnvironmentManagementController(
    EnvironmentManagementDependencies(
      environmentStoreState: scope.envState,
      workspaceController: workspaceController,
      context: scope.app.context,
      mounted: scope.app.mounted,
      workspaces: scope.ws.workspaces,
      activeWorkspace: scope.ws.activeWorkspace,
      showMessage: scope.app.showMessage,
      navigation: navigationController,
      mutations: mutations,
    ),
  );
}

WorkspaceShortcutController _createWorkspaceShortcutController({
  required _WorkspaceFactoryScope scope,
  required EnvironmentNavigationController navigationController,
  required WorkspaceLinksController workspaceLinksController,
}) {
  return WorkspaceShortcutController(
    WorkspaceShortcutDependencies(
      appUiState: scope.uiState,
      workspaceLinksController: workspaceLinksController,
      focusedWindowOrNull: scope.ws.focusedWindowOrNull,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
      toggleExpose: scope.ws.toggleExpose,
      toggleVideoPlayback: scope.ws.toggleVideoPlayback,
      navigation: navigationController,
    ),
  );
}

WorkspaceViewTrackingController _createWorkspaceViewTrackingController({required _WorkspaceFactoryScope scope}) {
  return WorkspaceViewTrackingController(
    WorkspaceViewTrackingDependencies(
      environmentStoreState: scope.envState,
      appUiState: scope.uiState,
      workspaceViewTrackingState: scope.trackingState,
      mounted: scope.app.mounted,
      activeWorkspace: scope.ws.activeWorkspace,
      updateEnvironment: scope.env.updateEnvironment,
    ),
  );
}

_MediaFlows _createMediaFlows({
  required _WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
}) {
  final videoFrameExporter = VideoFrameExporter(mediaInspector: scope.media);
  final workspaceVideoConversionPrompts = WorkspaceVideoConversionPrompts(context: scope.app.context);
  final workspaceVideoConversionController = WorkspaceVideoConversionController(
    showMessage: scope.app.showMessage,
    mediaInspector: scope.media,
    videoFrameExporter: videoFrameExporter,
    videoConversionPrompts: workspaceVideoConversionPrompts.confirmOverwriteJpeg,
    createFileBookmark: scope.platform.createFileBookmark,
    activeWorkspace: scope.ws.activeWorkspace,
    replaceWorkspace: scope.env.replaceWorkspace,
    colorFromDigest: scope.ws.colorFromDigest,
    removePausedVideoWindow: (windowId) {
      scope.app.commitStateChange(() {
        scope.interactionState.pausedVideoWindows.remove(windowId);
      });
    },
  );
  final workspaceMediaImportController = WorkspaceMediaImportController(
    imageExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'],
    videoExtensions: const ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'],
    environmentStoreState: scope.envState,
    activeWorkspace: () => scope.ws.activeWorkspace()!,
    confirmSingleFrameConversion: workspaceVideoConversionPrompts.confirmSingleFrameConversion,
    videoFrameExporter: videoFrameExporter,
    createFileBookmark: scope.platform.createFileBookmark,
    mediaInspector: scope.media,
    updateEnvironment: scope.store.updateEnvironment,
    thumbnailController: thumbnailController,
    showMessage: scope.app.showMessage,
  );

  return _MediaFlows(
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

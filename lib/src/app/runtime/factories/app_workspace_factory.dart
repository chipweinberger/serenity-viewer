import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:flutter/material.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_core.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_environment.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_media.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';

({
  WorkspaceController workspaceController,
  EnvironmentController environmentController,
  EnvironmentWindowHistoryController environmentWindowHistoryController,
})
createAppWorkspaceServices({
  required PlatformBridge platformBridge,
  required EnvironmentStore environmentStore,
  required MediaInspector mediaInspector,
  required AppUiController appUiController,
  required bool isRunningInWidgetTest,
  required BuildContext Function() context,
  required bool Function() mounted,
  required ValueChanged<String> showMessage,
  required ValueChanged<Environment> updateEnvironment,
  required void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace,
  required String Function(String prefix) newId,
  required int Function(String value) colorFromDigest,
  required Workspace? Function() activeWorkspace,
  required List<Workspace> Function() workspaces,
  required List<Workspace> Function() openWorkspaces,
  required Window? Function() focusedWindowOrNull,
  required void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport,
  required SerenityShowWorkspaceScreen showWorkspaceScreen,
  required SerenityShowLibraryScreen showLibraryScreen,
  required VoidCallback toggleExpose,
  required ValueChanged<String> toggleVideoPlayback,
  required EnvironmentStoreState envState,
  required AppUiState uiState,
  required WindowInteractionState interactionState,
  required WorkspaceViewTrackingState trackingState,
  required WorkspaceViewportState viewportState,
  required ThumbnailRefreshState thumbState,
  required EnvironmentWindowHistoryState environmentWindowHistoryState,
}) {
  final scope = WorkspaceFactoryScope(
    platform: platformBridge,
    store: environmentStore,
    media: mediaInspector,
    ui: appUiController,
    isRunningInWidgetTest: isRunningInWidgetTest,
    context: context,
    mounted: mounted,
    showMessage: showMessage,
    updateEnvironment: updateEnvironment,
    replaceWorkspace: replaceWorkspace,
    newId: newId,
    colorFromDigest: colorFromDigest,
    activeWorkspace: activeWorkspace,
    workspaces: workspaces,
    openWorkspaces: openWorkspaces,
    focusedWindowOrNull: focusedWindowOrNull,
    setWorkspaceViewport: setWorkspaceViewport,
    showWorkspaceScreen: showWorkspaceScreen,
    showLibraryScreen: showLibraryScreen,
    toggleExpose: toggleExpose,
    toggleVideoPlayback: toggleVideoPlayback,
    envState: envState,
    uiState: uiState,
    interactionState: interactionState,
    trackingState: trackingState,
    viewportState: viewportState,
    thumbState: thumbState,
  );

  final thumbnailController = createThumbnailController(scope: scope);
  final workspaceLinksController = createWorkspaceLinksController(scope: scope);
  final workspaceCoreControllers = createWorkspaceCoreControllers(
    scope: scope,
    thumbnailController: thumbnailController,
  );
  final workspaceWindowController = createWorkspaceWindowController(scope: scope, core: workspaceCoreControllers);
  final workspaceMediaServices = createWorkspaceMediaServices(scope: scope, thumbnailController: thumbnailController);
  final workspaceEnvironmentServices = createWorkspaceEnvironmentServices(
    scope: scope,
    thumbnailController: thumbnailController,
    exposeController: workspaceCoreControllers.expose,
    environmentController: workspaceCoreControllers.environment,
    workspaceLinksController: workspaceLinksController,
    workspaceWindowController: workspaceWindowController,
  );
  final environmentWindowHistoryController = createEnvironmentWindowHistoryController(
    scope: scope,
    environmentWindowHistoryState: environmentWindowHistoryState,
    core: workspaceCoreControllers,
  );
  final workspaceController = createWorkspaceController(
    core: workspaceCoreControllers,
    window: workspaceWindowController,
    media: workspaceMediaServices.media,
    layout: workspaceEnvironmentServices.layout,
    shortcuts: workspaceEnvironmentServices.shortcuts,
    links: workspaceLinksController,
    thumbnails: thumbnailController,
    tracking: workspaceEnvironmentServices.tracking,
  );

  return (
    workspaceController: workspaceController,
    environmentController: workspaceEnvironmentServices.environment,
    environmentWindowHistoryController: environmentWindowHistoryController,
  );
}

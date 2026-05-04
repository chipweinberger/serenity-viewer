import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_media_controller.dart';
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

import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';

typedef WorkspaceCoreControllers = ({
  WorkspaceGestureController gesture,
  WorkspaceExposeController expose,
  WorkspaceWindowsController windows,
  WorkspaceViewportController viewport,
  WorkspacePlaybackController playback,
  WorkspaceEnvironmentController environment,
});

ThumbnailController createThumbnailController({required WorkspaceFactoryScope scope}) {
  return ThumbnailController(
    state: scope.thumbState,
    refresher: ThumbnailRefresher(
      environmentStoreState: scope.envState,
      updateEnvironment: scope.store.updateEnvironment,
      renderer: ThumbnailRenderer(isRunningInWidgetTest: scope.isRunningInWidgetTest),
      store: ThumbnailStore(thumbnailDirectory: scope.platform.thumbnailDirectory),
    ),
    activeScreen: () => scope.uiState.screen,
    activeWorkspaceId: () => scope.activeWorkspace()?.id,
    viewportSize: () => scope.viewportState.viewportSize,
  );
}

WorkspaceLinksController createWorkspaceLinksController({required WorkspaceFactoryScope scope}) {
  return WorkspaceLinksController(
    screen: () => scope.uiState.screen,
    hasSession: () => scope.envState.environment != null,
    activeWorkspace: scope.activeWorkspace,
    workspaces: scope.workspaces,
    replaceWorkspace: scope.replaceWorkspace,
    newId: scope.newId,
    showMessage: scope.showMessage,
    mounted: scope.mounted,
    context: scope.context,
  );
}

WorkspaceController createWorkspaceController({
  required WorkspaceCoreControllers core,
  required WorkspaceWindowController window,
  required WorkspaceMediaController media,
  required WorkspaceExposeLayoutController layout,
  required WorkspaceShortcutController shortcuts,
  required WorkspaceLinksController links,
  required ThumbnailController thumbnails,
  required WorkspaceViewTrackingController tracking,
}) {
  return WorkspaceController(
    gesture: core.gesture,
    expose: core.expose,
    windows: core.windows,
    viewport: core.viewport,
    playback: core.playback,
    environment: core.environment,
    window: window,
    media: media,
    layout: layout,
    shortcuts: shortcuts,
    links: links,
    thumbnails: thumbnails,
    tracking: tracking,
  );
}

WorkspaceCoreControllers createWorkspaceCoreControllers({
  required WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
}) {
  final gesture = WorkspaceGestureController(windowInteractionState: scope.interactionState);
  final expose = WorkspaceExposeController(windowInteractionState: scope.interactionState);
  final windows = WorkspaceWindowsController(
    appUiState: scope.uiState,
    windowInteractionState: scope.interactionState,
    replaceWorkspace: scope.replaceWorkspace,
  );
  final viewport = WorkspaceViewportController(
    environmentStoreState: scope.envState,
    appUiState: scope.uiState,
    windowInteractionState: scope.interactionState,
    workspaceViewportState: scope.viewportState,
    thumbnailController: thumbnailController,
    replaceWorkspace: scope.replaceWorkspace,
    activeWorkspaceOrNull: scope.activeWorkspace,
    applyWorkspaceViewport: scope.setWorkspaceViewport,
    refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
  );
  final playback = WorkspacePlaybackController(
    windowInteractionState: scope.interactionState,
    replaceWorkspace: scope.replaceWorkspace,
    environment: () => scope.envState.environment,
    activeWorkspaceOrNull: scope.activeWorkspace,
  );
  final environment = WorkspaceEnvironmentController();

  return (
    gesture: gesture,
    expose: expose,
    windows: windows,
    viewport: viewport,
    playback: playback,
    environment: environment,
  );
}

WorkspaceWindowController createWorkspaceWindowController({
  required WorkspaceFactoryScope scope,
  required WorkspaceCoreControllers core,
}) {
  return WorkspaceWindowController(
    appUiState: scope.uiState,
    windowInteractionState: scope.interactionState,
    activeWorkspace: () => scope.activeWorkspace()!,
    activeWorkspaceOrNull: scope.activeWorkspace,
    gestureController: core.gesture,
    windowsController: core.windows,
  );
}

EnvironmentWindowHistoryController createEnvironmentWindowHistoryController({
  required WorkspaceFactoryScope scope,
  required EnvironmentWindowHistoryState environmentWindowHistoryState,
  required WorkspaceCoreControllers core,
}) {
  return EnvironmentWindowHistoryController(
    environment: () => scope.envState.environment,
    workspaces: scope.workspaces,
    activeWorkspace: scope.activeWorkspace,
    environmentWindowHistoryState: environmentWindowHistoryState,
    exposeController: core.expose,
    windowsController: core.windows,
    playbackController: core.playback,
    updateEnvironment: scope.store.updateEnvironment,
    replaceWorkspace: scope.store.replaceWorkspace,
    showMessage: scope.showMessage,
    showWorkspaceScreen: scope.showWorkspaceScreen,
    screen: () => scope.uiState.screen,
    maxRecentlyClosedWindows: 12,
  );
}

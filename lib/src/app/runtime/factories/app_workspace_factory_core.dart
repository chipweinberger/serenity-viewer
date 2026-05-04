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

WorkspaceGestureController createWorkspaceGestureController({required WorkspaceFactoryScope scope}) {
  return WorkspaceGestureController(windowInteractionState: scope.interactionState);
}

WorkspaceExposeController createWorkspaceExposeController({required WorkspaceFactoryScope scope}) {
  return WorkspaceExposeController(windowInteractionState: scope.interactionState);
}

WorkspaceWindowsController createWorkspaceWindowsController({required WorkspaceFactoryScope scope}) {
  return WorkspaceWindowsController(
    appUiState: scope.uiState,
    windowInteractionState: scope.interactionState,
    replaceWorkspace: scope.replaceWorkspace,
  );
}

WorkspaceViewportController createWorkspaceViewportController({
  required WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
}) {
  return WorkspaceViewportController(
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
}

WorkspacePlaybackController createWorkspacePlaybackController({required WorkspaceFactoryScope scope}) {
  return WorkspacePlaybackController(
    windowInteractionState: scope.interactionState,
    replaceWorkspace: scope.replaceWorkspace,
    environment: () => scope.envState.environment,
    activeWorkspaceOrNull: scope.activeWorkspace,
  );
}

WorkspaceEnvironmentController createWorkspaceEnvironmentController() {
  return WorkspaceEnvironmentController();
}

WorkspaceWindowController createWorkspaceWindowController({
  required WorkspaceFactoryScope scope,
  required WorkspaceGestureController gestureController,
  required WorkspaceWindowsController windowsController,
}) {
  return WorkspaceWindowController(
    appUiState: scope.uiState,
    windowInteractionState: scope.interactionState,
    activeWorkspace: () => scope.activeWorkspace()!,
    activeWorkspaceOrNull: scope.activeWorkspace,
    gestureController: gestureController,
    windowsController: windowsController,
  );
}

EnvironmentWindowHistoryController createEnvironmentWindowHistoryController({
  required WorkspaceFactoryScope scope,
  required EnvironmentWindowHistoryState environmentWindowHistoryState,
  required WorkspaceExposeController exposeController,
  required WorkspaceWindowsController windowsController,
  required WorkspacePlaybackController playbackController,
}) {
  return EnvironmentWindowHistoryController(
    environment: () => scope.envState.environment,
    workspaces: scope.workspaces,
    activeWorkspace: scope.activeWorkspace,
    environmentWindowHistoryState: environmentWindowHistoryState,
    exposeController: exposeController,
    windowsController: windowsController,
    playbackController: playbackController,
    updateEnvironment: scope.store.updateEnvironment,
    replaceWorkspace: scope.store.replaceWorkspace,
    showMessage: scope.showMessage,
    showWorkspaceScreen: scope.showWorkspaceScreen,
    screen: () => scope.uiState.screen,
    maxRecentlyClosedWindows: 12,
  );
}

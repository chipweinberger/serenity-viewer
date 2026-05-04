import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresher.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_renderer.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_store.dart';

import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';

WorkspaceAssetPickerController createWorkspaceAssetPickerController({
  required WorkspaceMediaImportController workspaceMediaImportController,
}) {
  return WorkspaceAssetPickerController(
    acceptedTypeGroups: () => workspaceMediaImportController.acceptedTypeGroups,
    importFiles: workspaceMediaImportController.importFiles,
  );
}

WorkspaceCollateController createWorkspaceCollateController({
  required WorkspaceFactoryScope scope,
  required WorkspaceWindowController workspaceWindowController,
}) {
  return WorkspaceCollateController(
    context: scope.context,
    showMessage: scope.showMessage,
    windowController: workspaceWindowController,
  );
}

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
  );
}

WorkspaceLinksLauncher createWorkspaceLinksLauncher({required WorkspaceFactoryScope scope}) {
  return WorkspaceLinksLauncher(showMessage: scope.showMessage, mounted: scope.mounted);
}

WorkspaceLinksPrompts createWorkspaceLinksPrompts({required WorkspaceFactoryScope scope}) {
  return WorkspaceLinksPrompts(context: scope.context);
}

WorkspaceController createWorkspaceController({
  required WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
}) {
  return WorkspaceController(
    appUiState: scope.uiState,
    windowInteractionState: scope.interactionState,
    workspaceViewportState: scope.viewportState,
    replaceWorkspace: scope.replaceWorkspace,
    setWorkspaceViewport: scope.setWorkspaceViewport,
    refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
  );
}

WorkspaceWindowController createWorkspaceWindowController({
  required WorkspaceFactoryScope scope,
  required WorkspaceController workspaceController,
}) {
  return WorkspaceWindowController(
    appUiState: scope.uiState,
    environment: () => scope.envState.environment,
    activeWorkspace: () => scope.activeWorkspace()!,
    activeWorkspaceOrNull: scope.activeWorkspace,
    workspaceController: workspaceController,
  );
}

WorkspaceViewportSessionController createWorkspaceViewportSessionController({
  required WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
}) {
  return WorkspaceViewportSessionController(
    environmentStoreState: scope.envState,
    workspaceViewportState: scope.viewportState,
    thumbnailController: thumbnailController,
    replaceWorkspace: scope.store.replaceWorkspace,
  );
}

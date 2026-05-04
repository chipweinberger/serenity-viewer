import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';

import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory_scope.dart';

EnvironmentNavigationController createEnvironmentNavigationController({
  required WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required WorkspaceController workspaceController,
}) {
  return EnvironmentNavigationController(
    EnvironmentNavigationDependencies(
      environmentStoreState: scope.envState,
      appUiState: scope.uiState,
      workspaceController: workspaceController,
      openWorkspaces: scope.openWorkspaces,
      updateEnvironment: scope.updateEnvironment,
      showWorkspaceScreen: scope.showWorkspaceScreen,
      showLibraryScreen: scope.showLibraryScreen,
      workspaceSwitchTarget: scope.ui.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    ),
  );
}

WorkspaceExposeLayoutController createWorkspaceExposeLayoutController({
  required WorkspaceFactoryScope scope,
  required WorkspaceWindowController workspaceWindowController,
}) {
  return WorkspaceExposeLayoutController(
    WorkspaceExposeLayoutDependencies(
      appUiState: scope.uiState,
      workspaceViewportState: scope.viewportState,
      context: scope.context,
      mounted: scope.mounted,
      activeWorkspace: scope.activeWorkspace,
      replaceWorkspace: scope.replaceWorkspace,
      showMessage: scope.showMessage,
      showWorkspaceScreen: scope.showWorkspaceScreen,
      windowController: workspaceWindowController,
    ),
  );
}

EnvironmentManagementMutations createEnvironmentManagementMutations({
  required WorkspaceFactoryScope scope,
  required ThumbnailController thumbnailController,
  required WorkspaceController workspaceController,
}) {
  return EnvironmentManagementMutations(
    EnvironmentManagementMutationDependencies(
      environmentStoreState: scope.envState,
      appUiState: scope.uiState,
      workspaceController: workspaceController,
      workspaces: scope.workspaces,
      updateEnvironment: scope.updateEnvironment,
      replaceWorkspace: scope.replaceWorkspace,
      showWorkspaceScreen: scope.showWorkspaceScreen,
      newId: scope.newId,
      queueWorkspaceRefresh: thumbnailController.queueWorkspaceRefresh,
    ),
  );
}

EnvironmentManagementController createEnvironmentManagementController({
  required WorkspaceFactoryScope scope,
  required EnvironmentNavigationController navigationController,
  required ThumbnailController thumbnailController,
  required WorkspaceController workspaceController,
}) {
  final mutations = createEnvironmentManagementMutations(
    scope: scope,
    thumbnailController: thumbnailController,
    workspaceController: workspaceController,
  );

  return EnvironmentManagementController(
    EnvironmentManagementDependencies(
      environmentStoreState: scope.envState,
      workspaceController: workspaceController,
      context: scope.context,
      mounted: scope.mounted,
      workspaces: scope.workspaces,
      activeWorkspace: scope.activeWorkspace,
      showMessage: scope.showMessage,
      navigation: navigationController,
      mutations: mutations,
    ),
  );
}

WorkspaceShortcutController createWorkspaceShortcutController({
  required WorkspaceFactoryScope scope,
  required EnvironmentNavigationController navigationController,
  required WorkspaceLinksController workspaceLinksController,
}) {
  return WorkspaceShortcutController(
    WorkspaceShortcutDependencies(
      appUiState: scope.uiState,
      workspaceLinksController: workspaceLinksController,
      focusedWindowOrNull: scope.focusedWindowOrNull,
      showWorkspaceScreen: scope.showWorkspaceScreen,
      toggleExpose: scope.toggleExpose,
      toggleVideoPlayback: scope.toggleVideoPlayback,
      navigation: navigationController,
    ),
  );
}

WorkspaceViewTrackingController createWorkspaceViewTrackingController({required WorkspaceFactoryScope scope}) {
  return WorkspaceViewTrackingController(
    WorkspaceViewTrackingDependencies(
      environmentStoreState: scope.envState,
      appUiState: scope.uiState,
      workspaceViewTrackingState: scope.trackingState,
      mounted: scope.mounted,
      activeWorkspace: scope.activeWorkspace,
      updateEnvironment: scope.updateEnvironment,
    ),
  );
}

import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_mutations.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
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
      openWorkspaces: scope.ws.openWorkspaces,
      updateEnvironment: scope.inputs.updateEnvironment,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
      showLibraryScreen: scope.ws.showLibraryScreen,
      workspaceSwitchTarget: scope.ui.workspaceSwitchTarget,
      refreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
    ),
  );
}

WorkspaceExposeLayoutController createWorkspaceExposeLayoutController({required WorkspaceFactoryScope scope}) {
  return WorkspaceExposeLayoutController(
    WorkspaceExposeLayoutDependencies(
      appUiState: scope.uiState,
      workspaceViewportState: scope.viewportState,
      context: scope.inputs.context,
      mounted: scope.inputs.mounted,
      activeWorkspace: scope.ws.activeWorkspace,
      replaceWorkspace: scope.inputs.replaceWorkspace,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
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
      workspaces: scope.ws.workspaces,
      updateEnvironment: scope.inputs.updateEnvironment,
      replaceWorkspace: scope.inputs.replaceWorkspace,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
      newId: scope.ws.newId,
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
      context: scope.inputs.context,
      mounted: scope.inputs.mounted,
      workspaces: scope.ws.workspaces,
      activeWorkspace: scope.ws.activeWorkspace,
      showMessage: scope.inputs.showMessage,
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
      focusedWindowOrNull: scope.ws.focusedWindowOrNull,
      showWorkspaceScreen: scope.ws.showWorkspaceScreen,
      toggleExpose: scope.ws.toggleExpose,
      toggleVideoPlayback: scope.ws.toggleVideoPlayback,
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
      mounted: scope.inputs.mounted,
      activeWorkspace: scope.ws.activeWorkspace,
      updateEnvironment: scope.inputs.updateEnvironment,
    ),
  );
}

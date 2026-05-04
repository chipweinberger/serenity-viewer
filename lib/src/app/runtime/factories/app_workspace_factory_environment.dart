part of 'app_workspace_factory.dart';

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

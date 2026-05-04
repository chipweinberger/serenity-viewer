part of 'app_workspace_factory.dart';

WorkspaceAssetPickerController _createWorkspaceAssetPickerController({
  required WorkspaceMediaImportController workspaceMediaImportController,
}) {
  return WorkspaceAssetPickerController(
    acceptedTypeGroups: () => workspaceMediaImportController.acceptedTypeGroups,
    importFiles: workspaceMediaImportController.importFiles,
  );
}

WorkspaceCollateController _createWorkspaceCollateController({
  required _WorkspaceFactoryScope scope,
  required WorkspaceWindowController workspaceWindowController,
}) {
  return WorkspaceCollateController(
    context: scope.app.context,
    showMessage: scope.app.showMessage,
    windowController: workspaceWindowController,
  );
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
    workspaceWindowHistoryState: scope.stateStore.workspaceWindowHistoryState,
    workspaceController: workspaceController,
    updateEnvironment: scope.store.updateEnvironment,
    replaceWorkspace: scope.store.replaceWorkspace,
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

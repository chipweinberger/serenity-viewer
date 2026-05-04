part of 'app_workspace_factory.dart';

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

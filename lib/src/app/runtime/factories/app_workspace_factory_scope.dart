part of 'app_workspace_factory.dart';

class _WorkspaceFactoryScope {
  const _WorkspaceFactoryScope({required this.inputs, required this.foundation});

  final AppRuntimeInputs inputs;
  final AppFoundation foundation;

  AppRuntimeAppInputs get app => inputs.app;
  AppRuntimeEnvironmentInputs get env => inputs.environment;
  AppRuntimeWorkspaceInputs get ws => inputs.workspace;
  AppStateStore get stateStore => inputs.stateStore;
  PlatformBridge get platform => foundation.platformBridge;
  EnvironmentStore get store => foundation.environmentStore;
  MediaInspector get media => foundation.mediaInspector;
  AppUiController get ui => foundation.appUiController;
  EnvironmentStoreState get envState => stateStore.environmentStoreState;
  AppUiState get uiState => stateStore.appUiState;
  WindowInteractionState get interactionState => stateStore.windowInteractionState;
  WorkspaceViewTrackingState get trackingState => stateStore.workspaceViewTrackingState;
  WorkspaceViewportState get viewportState => stateStore.workspaceViewportState;
  ThumbnailRefreshState get thumbState => stateStore.thumbnailRefreshState;
}

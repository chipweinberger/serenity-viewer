import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceFactoryScope {
  const WorkspaceFactoryScope({required this.inputs, required this.foundation});

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

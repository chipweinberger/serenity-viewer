import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceFactoryScope {
  const WorkspaceFactoryScope({
    required this.inputs,
    required this.platform,
    required this.store,
    required this.media,
    required this.ui,
    required this.envState,
    required this.uiState,
    required this.interactionState,
    required this.trackingState,
    required this.viewportState,
    required this.thumbState,
    required this.workspaceWindowHistoryState,
  });

  final AppRuntimeInputs inputs;
  final PlatformBridge platform;
  final EnvironmentStore store;
  final MediaInspector media;
  final AppUiController ui;
  final EnvironmentStoreState envState;
  final AppUiState uiState;
  final WindowInteractionState interactionState;
  final WorkspaceViewTrackingState trackingState;
  final WorkspaceViewportState viewportState;
  final ThumbnailRefreshState thumbState;
  final WorkspaceWindowHistoryState workspaceWindowHistoryState;
}

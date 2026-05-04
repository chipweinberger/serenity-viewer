import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppStateStore {
  final EnvironmentStoreState environmentStoreState = EnvironmentStoreState();
  final AppUiState appUiState = AppUiState();
  final WindowInteractionState windowInteractionState = WindowInteractionState();
  final WorkspaceViewTrackingState workspaceViewTrackingState = WorkspaceViewTrackingState();
  final WorkspaceViewportState workspaceViewportState = WorkspaceViewportState();
  final ThumbnailRefreshState thumbnailRefreshState = ThumbnailRefreshState();
  final WorkspaceWindowHistoryState workspaceWindowHistoryState = WorkspaceWindowHistoryState();

  void dispose() {
    environmentStoreState.dispose();
    appUiState.dispose();
    windowInteractionState.dispose();
    workspaceViewTrackingState.dispose();
    workspaceViewportState.dispose();
    thumbnailRefreshState.dispose();
    workspaceWindowHistoryState.dispose();
  }
}

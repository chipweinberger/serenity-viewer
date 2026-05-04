import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/behavior/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/workspace/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/session/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/window/session/recently_closed_windows_state.dart';

class AppDependencies {
  final AppHandles handles = AppHandles();
  final EnvironmentStoreState environmentStoreState = EnvironmentStoreState();
  final AppUiState appUiState = AppUiState();
  final WindowInteractionState windowInteractionState = WindowInteractionState();
  final WorkspaceViewTrackingState workspaceViewTrackingState = WorkspaceViewTrackingState();
  final WorkspaceViewportState workspaceViewportState = WorkspaceViewportState();
  final ThumbnailRefreshState thumbnailRefreshState = ThumbnailRefreshState();
  final RecentlyClosedWindowsState recentlyClosedWindowsState = RecentlyClosedWindowsState();
}

class AppHandles {
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  final ScrollController tabScrollController = ScrollController();

  void dispose() {
    tabScrollController.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}

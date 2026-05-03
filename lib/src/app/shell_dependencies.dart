import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/app/app_environment_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';

class ShellDependencies {
  final ShellHandles handles = ShellHandles();
  final AppEnvironmentState persistenceState = AppEnvironmentState();
  final ChromeState chromeState = ChromeState();
  final AssetWindowInteractionState windowInteractionState = AssetWindowInteractionState();
  final WorkspaceViewTrackingState workspaceViewTrackingState = WorkspaceViewTrackingState();
  final WorkspaceViewportState workspaceViewportState = WorkspaceViewportState();
  final ThumbnailRefreshState thumbnailRefreshState = ThumbnailRefreshState();
}

class ShellHandles {
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  final ScrollController tabScrollController = ScrollController();

  void dispose() {
    tabScrollController.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}

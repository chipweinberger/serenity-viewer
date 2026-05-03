import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/environments/session/shell_persistence_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';

class ShellDependencies {
  final ShellHandles handles = ShellHandles();
  final ShellPersistenceState persistenceState = ShellPersistenceState();
  final ChromeState chromeState = ChromeState();
  final WindowInteractionState windowInteractionState = WindowInteractionState();
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

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/environments/session/shell_persistence_state.dart';
import 'package:serenity_viewer/src/environments/persistence/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class SerenityShellDependencies {
  final SerenityShellHandles handles = SerenityShellHandles();
  final SerenityShellPersistenceState persistenceState = SerenityShellPersistenceState();
  final SerenityChromeState chromeState = SerenityChromeState();
  final SerenityWindowInteractionState windowInteractionState = SerenityWindowInteractionState();
  final SerenityWorkspaceViewTrackingState workspaceViewTrackingState = SerenityWorkspaceViewTrackingState();
  final SerenityWorkspaceViewportState workspaceViewportState = SerenityWorkspaceViewportState();
  final SerenityThumbnailRefreshState thumbnailRefreshState = SerenityThumbnailRefreshState();
}

class SerenityShellHandles {
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  final ScrollController tabScrollController = ScrollController();

  void dispose() {
    tabScrollController.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}

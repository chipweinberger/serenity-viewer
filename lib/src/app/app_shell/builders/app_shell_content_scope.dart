import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_window_history_controller.dart';
import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppShellContentState {
  const AppShellContentState({
    required this.context,
    required this.uiState,
    required this.environment,
    required this.windowTitle,
    required this.workspaces,
    required this.openWorkspaces,
    required this.activeWorkspace,
    required this.activeWorkspaceOrNull,
    required this.selectedExposeWindowCount,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.chromeController,
    required this.mediaBridge,
    required this.workspaceShellController,
    required this.workspaceLinksController,
    required this.thumbnailController,
    required this.windowHistoryController,
    required this.searchController,
    required this.tabScrollController,
  });

  final BuildContext context;
  final ChromeState uiState;
  final Environment environment;
  final String windowTitle;
  final List<Workspace> workspaces;
  final List<Workspace> openWorkspaces;
  final Workspace activeWorkspace;
  final Workspace? activeWorkspaceOrNull;
  final int selectedExposeWindowCount;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final ChromeController chromeController;
  final MediaBridge mediaBridge;
  final WorkspaceShellController workspaceShellController;
  final LinksController workspaceLinksController;
  final ThumbnailController thumbnailController;
  final AppShellWindowHistoryController windowHistoryController;
  final TextEditingController searchController;
  final ScrollController tabScrollController;
}

class AppShellContentActions {
  const AppShellContentActions({
    required this.commitStateChange,
    required this.importFiles,
    required this.handleOptionGestureHover,
    required this.handleWorkspacePanZoomStart,
    required this.handleWorkspacePanZoomUpdate,
    required this.handleWorkspacePanZoomEnd,
    required this.focusWindow,
    required this.restorePreviousWindowZOrder,
    required this.moveWindow,
    required this.resizeWindow,
    required this.transformWindowFromTrackpad,
    required this.fitWindowToContent,
    required this.setWindowZoom,
    required this.setVideoPosition,
    required this.cycleVideoPlaybackSpeed,
    required this.setWindowIntrinsicSize,
    required this.isVideoWindowPaused,
    required this.toggleVideoPlayback,
    required this.toggleExpose,
    required this.setPinnedHoverWindow,
    required this.clearPinnedHoverWindow,
    required this.flashWindow,
    required this.setActiveGestureWindow,
    required this.fitWorkspaceViewportToContent,
    required this.confirmCollateWorkspaceWindows,
    required this.setWorkspaceViewport,
  });

  final void Function(VoidCallback fn) commitStateChange;
  final Future<void> Function(List<XFile> files) importFiles;
  final void Function(PointerHoverEvent event, Workspace workspace) handleOptionGestureHover;
  final void Function(PointerPanZoomStartEvent event, Workspace workspace) handleWorkspacePanZoomStart;
  final void Function(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize)
  handleWorkspacePanZoomUpdate;
  final VoidCallback handleWorkspacePanZoomEnd;
  final ValueChanged<String> focusWindow;
  final ValueChanged<String> restorePreviousWindowZOrder;
  final void Function(String windowId, Offset delta) moveWindow;
  final void Function(String windowId, AssetWindowResizeHandle handle, Offset delta) resizeWindow;
  final void Function(String windowId, double scaleDelta, Offset localFocalPoint) transformWindowFromTrackpad;
  final ValueChanged<String> fitWindowToContent;
  final void Function(String windowId, AssetWindowZoomUpdate update) setWindowZoom;
  final void Function(String windowId, int positionMs) setVideoPosition;
  final ValueChanged<String> cycleVideoPlaybackSpeed;
  final void Function(String windowId, Size intrinsicSize) setWindowIntrinsicSize;
  final bool Function(String windowId) isVideoWindowPaused;
  final ValueChanged<String> toggleVideoPlayback;
  final VoidCallback toggleExpose;
  final ValueChanged<String> setPinnedHoverWindow;
  final VoidCallback clearPinnedHoverWindow;
  final ValueChanged<String> flashWindow;
  final ValueChanged<String?> setActiveGestureWindow;
  final VoidCallback fitWorkspaceViewportToContent;
  final Future<void> Function() confirmCollateWorkspaceWindows;
  final void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport;
}

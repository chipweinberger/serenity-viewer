import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/window/frame/window_resize_helpers.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_zoom_update.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppMainViewModel {
  const AppMainViewModel({
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
  });

  final AppUiState uiState;
  final Environment environment;
  final String windowTitle;
  final List<Workspace> workspaces;
  final List<Workspace> openWorkspaces;
  final Workspace activeWorkspace;
  final Workspace? activeWorkspaceOrNull;
  final int selectedExposeWindowCount;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
}

class AppMainViewServices {
  const AppMainViewServices({
    required this.appUiController,
    required this.sharedVideoControllerPool,
    required this.environmentController,
    required this.workspaceExposeLayoutController,
    required this.workspaceLinksController,
    required this.workspaceLinksLauncher,
    required this.workspaceLinksPrompts,
    required this.thumbnailController,
    required this.windowHistoryController,
    required this.searchController,
    required this.tabScrollController,
  });

  final AppUiController appUiController;
  final SharedVideoControllerPool sharedVideoControllerPool;
  final EnvironmentController environmentController;
  final WorkspaceExposeLayoutController workspaceExposeLayoutController;
  final WorkspaceLinksController workspaceLinksController;
  final WorkspaceLinksLauncher workspaceLinksLauncher;
  final WorkspaceLinksPrompts workspaceLinksPrompts;
  final ThumbnailController thumbnailController;
  final WorkspaceWindowHistoryController windowHistoryController;
  final TextEditingController searchController;
  final ScrollController tabScrollController;
}

class AppMainViewActions {
  const AppMainViewActions({required this.app, required this.window, required this.workspace});

  final AppActions app;
  final WindowActions window;
  final WorkspaceActions workspace;
}

class AppActions {
  const AppActions({required this.state, required this.files, required this.platform});

  final AppStateActions state;
  final AppFileActions files;
  final AppPlatformActions platform;
}

class AppStateActions {
  const AppStateActions({required this.commitStateChange});

  final void Function(VoidCallback fn) commitStateChange;
}

class AppFileActions {
  const AppFileActions({required this.importFiles});

  final Future<void> Function(List<XFile> files) importFiles;
}

class AppPlatformActions {
  const AppPlatformActions({required this.revealAssetInFinder});

  final Future<void> Function(Asset asset) revealAssetInFinder;
}

class WindowActions {
  const WindowActions({required this.interaction, required this.layout, required this.playback});

  final WindowInteractionActions interaction;
  final WindowLayoutActions layout;
  final WindowPlaybackActions playback;
}

class WindowInteractionActions {
  const WindowInteractionActions({
    required this.handleOptionGestureHover,
    required this.focusWindow,
    required this.setPinnedHoverWindow,
    required this.clearPinnedHoverWindow,
    required this.flashWindow,
    required this.setActiveGestureWindow,
  });

  final void Function(PointerHoverEvent event, Workspace workspace) handleOptionGestureHover;
  final ValueChanged<String> focusWindow;
  final ValueChanged<String> setPinnedHoverWindow;
  final VoidCallback clearPinnedHoverWindow;
  final ValueChanged<String> flashWindow;
  final ValueChanged<String?> setActiveGestureWindow;
}

class WindowLayoutActions {
  const WindowLayoutActions({
    required this.restorePreviousWindowZOrder,
    required this.moveWindow,
    required this.resizeWindow,
    required this.transformWindowFromTrackpad,
    required this.fitWindowToContent,
    required this.setWindowZoom,
    required this.setWindowIntrinsicSize,
  });

  final ValueChanged<String> restorePreviousWindowZOrder;
  final void Function(String windowId, Offset delta) moveWindow;
  final void Function(String windowId, WindowResizeHandle handle, Offset delta) resizeWindow;
  final void Function(String windowId, double scaleDelta, Offset localFocalPoint) transformWindowFromTrackpad;
  final ValueChanged<String> fitWindowToContent;
  final void Function(String windowId, WindowZoomUpdate update) setWindowZoom;
  final void Function(String windowId, Size intrinsicSize) setWindowIntrinsicSize;
}

class WindowPlaybackActions {
  const WindowPlaybackActions({
    required this.setVideoPosition,
    required this.cycleVideoPlaybackSpeed,
    required this.isVideoWindowPaused,
    required this.toggleVideoPlayback,
  });

  final void Function(String windowId, int positionMs) setVideoPosition;
  final ValueChanged<String> cycleVideoPlaybackSpeed;
  final bool Function(String windowId) isVideoWindowPaused;
  final ValueChanged<String> toggleVideoPlayback;
}

class WorkspaceActions {
  const WorkspaceActions({required this.viewport, required this.layout, required this.mode});

  final WorkspaceViewportActions viewport;
  final WorkspaceLayoutActions layout;
  final WorkspaceModeActions mode;
}

class WorkspaceViewportActions {
  const WorkspaceViewportActions({
    required this.handleWorkspacePanZoomStart,
    required this.handleWorkspacePanZoomUpdate,
    required this.handleWorkspacePanZoomEnd,
    required this.fitWorkspaceViewportToContent,
    required this.setWorkspaceViewport,
  });

  final void Function(PointerPanZoomStartEvent event, Workspace workspace) handleWorkspacePanZoomStart;
  final void Function(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize)
  handleWorkspacePanZoomUpdate;
  final VoidCallback handleWorkspacePanZoomEnd;
  final VoidCallback fitWorkspaceViewportToContent;
  final void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport;
}

class WorkspaceLayoutActions {
  const WorkspaceLayoutActions({required this.confirmCollateWorkspaceWindows});

  final Future<void> Function() confirmCollateWorkspaceWindows;
}

class WorkspaceModeActions {
  const WorkspaceModeActions({required this.toggleExpose});

  final VoidCallback toggleExpose;
}

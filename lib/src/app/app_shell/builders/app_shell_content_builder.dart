// ignore_for_file: invalid_use_of_protected_member

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_overlay.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_view_model.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';
import 'package:serenity_viewer/src/workspace_loading/workspace_load_plan.dart';

class AppShellContentBuilder {
  const AppShellContentBuilder({
    required this.context,
    required this.uiState,
    required this.environment,
    required this.windowTitle,
    required this.workspaces,
    required this.openWorkspaces,
    required this.activeWorkspace,
    required this.activeWorkspaceOrNull,
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

  final BuildContext context;
  final ChromeState uiState;
  final Environment environment;
  final String windowTitle;
  final List<Workspace> workspaces;
  final List<Workspace> openWorkspaces;
  final Workspace activeWorkspace;
  final Workspace? activeWorkspaceOrNull;
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

  Widget build() {
    final workspaceLoadPlan = buildWorkspaceLoadPlan(environment: environment, activeWorkspace: activeWorkspaceOrNull);
    mediaBridge.syncSharedVideoControllers(loadPlan: workspaceLoadPlan, environment: environment);
    final workspaceChromeViewModel = _buildWorkspaceChromeViewModel();

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex,
            children: [
              _buildWorkspaceScreen(workspaceLoadPlan, workspaceChromeViewModel),
              _buildLibraryScreen(workspaceLoadPlan),
            ],
          ),
        ),
        _buildWorkspaceChromeOverlay(),
      ],
    );
  }

  int get _activeScreenIndex {
    return switch (uiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  WorkspaceChromeViewModel _buildWorkspaceChromeViewModel() {
    final mediaCounts = workspaceMediaCounts(activeWorkspace);
    return WorkspaceChromeViewModel(
      imageLabel: '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}',
      videoLabel: '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}',
      linkLabel: '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}',
      isExposeMode: chromeController.isExposeMode,
      showExposeSelectionHud: chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      selectedCount: windowInteractionState.selectedExposeWindowIds.length,
      workspaceId: activeWorkspace.id,
      workspaceZoom: activeWorkspace.viewportZoom,
    );
  }

  Widget _buildWorkspaceScreen(MediaLoadPlan workspaceLoadPlan, WorkspaceChromeViewModel workspaceChromeViewModel) {
    return WorkspaceScreen(
      environment: environment,
      openWorkspaces: openWorkspaces,
      chromeState: uiState,
      windowInteractionState: windowInteractionState,
      loadPlan: workspaceLoadPlan,
      sharedVideoLookup: mediaBridge.sharedVideoForWindow,
      actions: WorkspaceScreenActions(
        setDropTargetActive: (isActive) => commitStateChange(() => uiState.isDropTargetActive = isActive),
        importFiles: importFiles,
        trackViewportSize: (viewportSize) => workspaceViewportState.viewportSize = viewportSize,
        handleOptionGestureHover: handleOptionGestureHover,
        handleWorkspacePanZoomStart: handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: handleWorkspacePanZoomEnd,
        focusWindow: focusWindow,
        restorePreviousWindowZOrder: restorePreviousWindowZOrder,
        moveWindow: moveWindow,
        resizeWindow: resizeWindow,
        transformWindowFromTrackpad: transformWindowFromTrackpad,
        fitWindowToContent: fitWindowToContent,
        setWindowZoom: setWindowZoom,
        setVideoPosition: setVideoPosition,
        cycleVideoPlaybackSpeed: cycleVideoPlaybackSpeed,
        setWindowIntrinsicSize: setWindowIntrinsicSize,
        isVideoWindowPaused: isVideoWindowPaused,
        toggleVideoPlayback: toggleVideoPlayback,
        toggleExpose: toggleExpose,
        setPinnedHoverWindow: setPinnedHoverWindow,
        clearPinnedHoverWindow: clearPinnedHoverWindow,
        flashWindow: flashWindow,
        toggleSelectedWindow: workspaceShellController.navigation.toggleSelectedWindow,
        removeWindow: windowHistoryController.removeWindow,
        setActiveGestureWindow: setActiveGestureWindow,
        revealAssetInFinder: mediaBridge.revealAssetInFinder,
      ),
      workspaceHud: WorkspaceHud(
        viewModel: workspaceChromeViewModel,
        actions: WorkspaceHudActions(
          onToggleExpose: toggleExpose,
          onFitWorkspaceViewportToContent: fitWorkspaceViewportToContent,
          onConfirmCollateWorkspaceWindows: confirmCollateWorkspaceWindows,
          onConfirmApplyExposeGridToWorkspace: workspaceShellController.navigation.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showSerenityLinksDialog(
            context: context,
            initialWorkspace: activeWorkspace,
            controller: workspaceLinksController,
          ),
          onClearExposeSelection: workspaceShellController.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) =>
              setWorkspaceViewport(workspaceId: workspaceId, zoom: zoom, queueThumbnail: false),
          onRefreshActiveWorkspaceThumbnail: thumbnailController.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }

  Widget _buildLibraryScreen(MediaLoadPlan workspaceLoadPlan) {
    return LibraryScreen(
      allWorkspaces: workspaces,
      openWorkspaces: openWorkspaces,
      loadPlan: workspaceLoadPlan,
      searchController: searchController,
      workspaceSort: uiState.workspaceSort,
      refreshingWorkspaceIds: thumbnailController.refreshingWorkspaceIds,
      actions: LibraryScreenActions(
        onSearchChanged: (_) => commitStateChange(() {}),
        onWorkspaceSortChanged: chromeController.setWorkspaceSort,
        onToggleWorkspaceOpen: workspaceShellController.management.toggleWorkspaceOpen,
        onRenameWorkspace: workspaceShellController.management.renameWorkspace,
        onDeleteWorkspace: workspaceShellController.management.confirmDeleteWorkspace,
        onSetActiveWorkspace: workspaceShellController.navigation.setActiveWorkspace,
      ),
    );
  }

  Widget _buildWorkspaceChromeOverlay() {
    return WorkspaceChromeOverlay(
      windowTitle: windowTitle,
      openWorkspaces: openWorkspaces,
      activeWorkspaceId: environment.activeWorkspaceId,
      isLibraryScreen: chromeController.isLibraryScreen,
      shouldMoveSelectedWindows: chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: uiState.draggingTabWorkspaceId,
      tabScrollController: tabScrollController,
      actions: WorkspaceChromeOverlayActions(
        onShowWorkspaceOverview: workspaceShellController.navigation.showOverview,
        onSetDraggingTabWorkspaceId: chromeController.setDraggingTabWorkspaceId,
        onReorderOpenWorkspace: workspaceShellController.management.reorderOpenWorkspace,
        onMoveSelectedExposeWindowsToWorkspace:
            workspaceShellController.management.moveSelectedExposeWindowsToWorkspace,
        onSetActiveWorkspace: workspaceShellController.navigation.setActiveWorkspace,
        onConfirmCloseTab: workspaceShellController.management.confirmCloseTab,
        onCreateWorkspace: workspaceShellController.management.createWorkspace,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_scope.dart';
import 'package:serenity_viewer/src/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_view_model.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';
import 'package:serenity_viewer/src/workspace_loading/workspace_load_plan.dart';

class AppShellWorkspaceContentBuilder {
  const AppShellWorkspaceContentBuilder({required this.state, required this.actions});

  final AppShellContentState state;
  final AppShellContentActions actions;

  WorkspaceChromeViewModel _buildWorkspaceChromeViewModel() {
    final mediaCounts = workspaceMediaCounts(state.activeWorkspace);
    return WorkspaceChromeViewModel(
      imageLabel: '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}',
      videoLabel: '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}',
      linkLabel: '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}',
      isExposeMode: state.chromeController.isExposeMode,
      showExposeSelectionHud: state.chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      selectedCount: state.selectedExposeWindowCount,
      workspaceId: state.activeWorkspace.id,
      workspaceZoom: state.activeWorkspace.viewportZoom,
    );
  }

  Widget build(MediaLoadPlan workspaceLoadPlan) {
    final workspaceChromeViewModel = _buildWorkspaceChromeViewModel();

    return WorkspaceScreen(
      environment: state.environment,
      openWorkspaces: state.openWorkspaces,
      chromeState: state.uiState,
      windowInteractionState: state.windowInteractionState,
      loadPlan: workspaceLoadPlan,
      sharedVideoLookup: state.mediaBridge.sharedVideoForWindow,
      actions: WorkspaceScreenActions(
        setDropTargetActive: (isActive) => actions.commitStateChange(() => state.uiState.isDropTargetActive = isActive),
        importFiles: actions.importFiles,
        trackViewportSize: (viewportSize) => state.workspaceViewportState.viewportSize = viewportSize,
        handleOptionGestureHover: actions.handleOptionGestureHover,
        handleWorkspacePanZoomStart: actions.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: actions.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: actions.handleWorkspacePanZoomEnd,
        focusWindow: actions.focusWindow,
        restorePreviousWindowZOrder: actions.restorePreviousWindowZOrder,
        moveWindow: actions.moveWindow,
        resizeWindow: actions.resizeWindow,
        transformWindowFromTrackpad: actions.transformWindowFromTrackpad,
        fitWindowToContent: actions.fitWindowToContent,
        setWindowZoom: actions.setWindowZoom,
        setVideoPosition: actions.setVideoPosition,
        cycleVideoPlaybackSpeed: actions.cycleVideoPlaybackSpeed,
        setWindowIntrinsicSize: actions.setWindowIntrinsicSize,
        isVideoWindowPaused: actions.isVideoWindowPaused,
        toggleVideoPlayback: actions.toggleVideoPlayback,
        toggleExpose: actions.toggleExpose,
        setPinnedHoverWindow: actions.setPinnedHoverWindow,
        clearPinnedHoverWindow: actions.clearPinnedHoverWindow,
        flashWindow: actions.flashWindow,
        toggleSelectedWindow: state.workspaceShellController.navigation.toggleSelectedWindow,
        removeWindow: state.windowHistoryController.removeWindow,
        setActiveGestureWindow: actions.setActiveGestureWindow,
        revealAssetInFinder: state.mediaBridge.revealAssetInFinder,
      ),
      workspaceHud: WorkspaceHud(
        viewModel: workspaceChromeViewModel,
        actions: WorkspaceHudActions(
          onToggleExpose: actions.toggleExpose,
          onFitWorkspaceViewportToContent: actions.fitWorkspaceViewportToContent,
          onConfirmCollateWorkspaceWindows: actions.confirmCollateWorkspaceWindows,
          onConfirmApplyExposeGridToWorkspace:
              state.workspaceShellController.navigation.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showSerenityLinksDialog(
            context: state.context,
            initialWorkspace: state.activeWorkspace,
            controller: state.workspaceLinksController,
          ),
          onClearExposeSelection: state.workspaceShellController.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) =>
              actions.setWorkspaceViewport(workspaceId: workspaceId, zoom: zoom, queueThumbnail: false),
          onRefreshActiveWorkspaceThumbnail: state.thumbnailController.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }
}

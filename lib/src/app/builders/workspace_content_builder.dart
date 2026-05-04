import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/builders/content_scope.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud_view_model.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

class WorkspaceContentBuilder {
  const WorkspaceContentBuilder({required this.state, required this.actions});

  final ContentState state;
  final ContentActions actions;

  WorkspaceHudViewModel _buildWorkspaceHudViewModel() {
    final mediaCounts = workspaceMediaCounts(state.activeWorkspace);
    return WorkspaceHudViewModel(
      imageLabel: '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}',
      videoLabel: '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}',
      linkLabel: '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}',
      isExposeMode: state.appUiController.isExposeMode,
      showExposeSelectionHud: state.appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      selectedCount: state.selectedExposeWindowCount,
      workspaceId: state.activeWorkspace.id,
      workspaceZoom: state.activeWorkspace.viewportZoom,
    );
  }

  Widget build(MediaLoadPlan workspaceLoadPlan) {
    final workspaceHudViewModel = _buildWorkspaceHudViewModel();

    return WorkspaceScreen(
      environment: state.environment,
      openWorkspaces: state.openWorkspaces,
      appUiState: state.uiState,
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
        toggleSelectedWindow: state.environmentController.navigation.toggleSelectedWindow,
        removeWindow: state.windowHistoryController.removeWindow,
        setActiveGestureWindow: actions.setActiveGestureWindow,
        revealAssetInFinder: state.mediaBridge.revealAssetInFinder,
      ),
      workspaceHud: WorkspaceHud(
        viewModel: workspaceHudViewModel,
        actions: WorkspaceHudActions(
          onToggleExpose: actions.toggleExpose,
          onFitWorkspaceViewportToContent: actions.fitWorkspaceViewportToContent,
          onConfirmCollateWorkspaceWindows: actions.confirmCollateWorkspaceWindows,
          onConfirmApplyExposeGridToWorkspace: state.environmentController.navigation.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showSerenityLinksDialog(
            context: state.context,
            initialWorkspace: state.activeWorkspace,
            controller: state.workspaceLinksController,
          ),
          onClearExposeSelection: state.environmentController.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) =>
              actions.setWorkspaceViewport(workspaceId: workspaceId, zoom: zoom, queueThumbnail: false),
          onRefreshActiveWorkspaceThumbnail: state.thumbnailController.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }
}

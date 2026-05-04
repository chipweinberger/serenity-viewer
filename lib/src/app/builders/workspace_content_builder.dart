import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/builders/app_screen_host_scope.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen_host.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

class WorkspaceContentBuilder {
  const WorkspaceContentBuilder({required this.state, required this.actions});

  final AppScreenHostState state;
  final AppScreenHostActions actions;

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

    return WorkspaceScreenHost(
      environment: state.environment,
      openWorkspaces: state.openWorkspaces,
      appUiState: state.uiState,
      windowInteractionState: state.windowInteractionState,
      loadPlan: workspaceLoadPlan,
      sharedVideoLookup: state.sharedVideoControllerPool.sharedVideoForWindow,
      actions: WorkspaceScreenHostActions(
        setDropTargetActive: (isActive) =>
            actions.app.commitStateChange(() => state.uiState.isDropTargetActive = isActive),
        importFiles: actions.app.importFiles,
        trackViewportSize: (viewportSize) => state.workspaceViewportState.viewportSize = viewportSize,
        handleOptionGestureHover: actions.window.handleOptionGestureHover,
        handleWorkspacePanZoomStart: actions.workspace.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: actions.workspace.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: actions.workspace.handleWorkspacePanZoomEnd,
        focusWindow: actions.window.focusWindow,
        restorePreviousWindowZOrder: actions.window.restorePreviousWindowZOrder,
        moveWindow: actions.window.moveWindow,
        resizeWindow: actions.window.resizeWindow,
        transformWindowFromTrackpad: actions.window.transformWindowFromTrackpad,
        fitWindowToContent: actions.window.fitWindowToContent,
        setWindowZoom: actions.window.setWindowZoom,
        setVideoPosition: actions.window.setVideoPosition,
        cycleVideoPlaybackSpeed: actions.window.cycleVideoPlaybackSpeed,
        setWindowIntrinsicSize: actions.window.setWindowIntrinsicSize,
        isVideoWindowPaused: actions.window.isVideoWindowPaused,
        toggleVideoPlayback: actions.window.toggleVideoPlayback,
        toggleExpose: actions.workspace.toggleExpose,
        setPinnedHoverWindow: actions.window.setPinnedHoverWindow,
        clearPinnedHoverWindow: actions.window.clearPinnedHoverWindow,
        flashWindow: actions.window.flashWindow,
        toggleSelectedWindow: state.environmentSession.navigation.toggleSelectedWindow,
        removeWindow: state.windowHistoryController.removeWindow,
        setActiveGestureWindow: actions.window.setActiveGestureWindow,
        revealAssetInFinder: actions.app.revealAssetInFinder,
      ),
      workspaceHud: WorkspaceHud(
        viewModel: workspaceHudViewModel,
        actions: WorkspaceHudActions(
          onToggleExpose: actions.workspace.toggleExpose,
          onFitWorkspaceViewportToContent: actions.workspace.fitWorkspaceViewportToContent,
          onConfirmCollateWorkspaceWindows: actions.workspace.confirmCollateWorkspaceWindows,
          onConfirmApplyExposeGridToWorkspace: state.environmentSession.expose.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showWorkspaceLinksDialog(
            context: state.context,
            initialWorkspace: state.activeWorkspace,
            controller: state.workspaceLinksController,
            prompts: state.workspaceLinksPrompts,
          ),
          onClearExposeSelection: state.environmentSession.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) =>
              actions.workspace.setWorkspaceViewport(workspaceId: workspaceId, zoom: zoom, queueThumbnail: false),
          onRefreshActiveWorkspaceThumbnail: state.thumbnailController.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }
}

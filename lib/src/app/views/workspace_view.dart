import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_main_view_data.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

class WorkspaceView extends StatelessWidget {
  const WorkspaceView({super.key, required this.state, required this.actions, required this.workspaceLoadPlan});

  final AppMainViewState state;
  final AppMainViewActions actions;
  final MediaLoadPlan workspaceLoadPlan;

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

  @override
  Widget build(BuildContext context) {
    final workspaceHudViewModel = _buildWorkspaceHudViewModel();

    return WorkspaceScreen(
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
        toggleSelectedWindow: state.environmentController.navigation.toggleSelectedWindow,
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
          onConfirmApplyExposeGridToWorkspace: state.workspaceExposeLayoutController.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showWorkspaceLinksDialog(
            context: state.context,
            initialWorkspace: state.activeWorkspace,
            controller: state.workspaceLinksController,
            launcher: state.workspaceLinksLauncher,
            prompts: state.workspaceLinksPrompts,
          ),
          onClearExposeSelection: state.environmentController.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) =>
              actions.workspace.setWorkspaceViewport(workspaceId: workspaceId, zoom: zoom, queueThumbnail: false),
          onRefreshActiveWorkspaceThumbnail: state.thumbnailController.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }
}

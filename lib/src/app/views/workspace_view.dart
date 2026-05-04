import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

class WorkspaceView extends StatelessWidget {
  const WorkspaceView({
    super.key,
    required this.model,
    required this.services,
    required this.actions,
    required this.workspaceLoadPlan,
  });

  final AppMainViewModel model;
  final AppMainViewServices services;
  final AppMainViewActions actions;
  final MediaLoadPlan workspaceLoadPlan;

  WorkspaceHudViewModel _buildWorkspaceHudViewModel() {
    final mediaCounts = workspaceMediaCounts(model.activeWorkspace);
    return WorkspaceHudViewModel(
      imageLabel: '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}',
      videoLabel: '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}',
      linkLabel: '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}',
      isExposeMode: services.appUiController.isExposeMode,
      showExposeSelectionHud: services.appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      selectedCount: model.selectedExposeWindowCount,
      workspaceId: model.activeWorkspace.id,
      workspaceZoom: model.activeWorkspace.viewportZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspaceHudViewModel = _buildWorkspaceHudViewModel();

    return WorkspaceScreen(
      environment: model.environment,
      openWorkspaces: model.openWorkspaces,
      appUiState: model.uiState,
      windowInteractionState: model.windowInteractionState,
      loadPlan: workspaceLoadPlan,
      sharedVideoLookup: services.sharedVideoControllerPool.sharedVideoForWindow,
      actions: WorkspaceScreenHostActions(
        setDropTargetActive: model.uiState.setDropTargetActive,
        importFiles: actions.app.files.importFiles,
        trackViewportSize: model.workspaceViewportState.setViewportSize,
        handleOptionGestureHover: actions.window.interaction.handleOptionGestureHover,
        handleWorkspacePanZoomStart: actions.workspace.viewport.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: actions.workspace.viewport.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: actions.workspace.viewport.handleWorkspacePanZoomEnd,
        focusWindow: actions.window.interaction.focusWindow,
        restorePreviousWindowZOrder: actions.window.layout.restorePreviousWindowZOrder,
        moveWindow: actions.window.layout.moveWindow,
        resizeWindow: actions.window.layout.resizeWindow,
        transformWindowFromTrackpad: actions.window.layout.transformWindowFromTrackpad,
        fitWindowToContent: actions.window.layout.fitWindowToContent,
        setWindowZoom: actions.window.layout.setWindowZoom,
        setVideoPosition: actions.window.playback.setVideoPosition,
        cycleVideoPlaybackSpeed: actions.window.playback.cycleVideoPlaybackSpeed,
        setWindowIntrinsicSize: actions.window.layout.setWindowIntrinsicSize,
        isVideoWindowPaused: actions.window.playback.isVideoWindowPaused,
        toggleVideoPlayback: actions.window.playback.toggleVideoPlayback,
        toggleExpose: actions.workspace.mode.toggleExpose,
        setPinnedHoverWindow: actions.window.interaction.setPinnedHoverWindow,
        clearPinnedHoverWindow: actions.window.interaction.clearPinnedHoverWindow,
        flashWindow: actions.window.interaction.flashWindow,
        toggleSelectedWindow: services.environmentController.navigation.toggleSelectedWindow,
        removeWindow: services.windowHistoryController.removeWindow,
        setActiveGestureWindow: actions.window.interaction.setActiveGestureWindow,
        revealAssetInFinder: actions.app.platform.revealAssetInFinder,
      ),
      workspaceHud: WorkspaceHud(
        viewModel: workspaceHudViewModel,
        actions: WorkspaceHudActions(
          onToggleExpose: actions.workspace.mode.toggleExpose,
          onFitWorkspaceViewportToContent: actions.workspace.viewport.fitWorkspaceViewportToContent,
          onConfirmCollateWorkspaceWindows: actions.workspace.layout.confirmCollateWorkspaceWindows,
          onConfirmApplyExposeGridToWorkspace:
              services.workspaceExposeLayoutController.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showWorkspaceLinksDialog(
            context: context,
            initialWorkspace: model.activeWorkspace,
            controller: services.workspaceLinksController,
            launcher: services.workspaceLinksLauncher,
            prompts: services.workspaceLinksPrompts,
          ),
          onClearExposeSelection: services.environmentController.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) => actions.workspace.viewport.setWorkspaceViewport(
            workspaceId: workspaceId,
            zoom: zoom,
            queueThumbnail: false,
          ),
          onRefreshActiveWorkspaceThumbnail: services.thumbnailController.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';

class WorkspaceView extends StatelessWidget {
  const WorkspaceView({super.key});

  ({
    AppUiState appUiState,
    EnvironmentStoreState environmentStoreState,
    WindowInteractionState windowInteractionState,
    WorkspaceViewportState workspaceViewportState,
  })
  _watchState(BuildContext context) {
    return (
      appUiState: context.watch<AppUiState>(),
      environmentStoreState: context.watch<EnvironmentStoreState>(),
      windowInteractionState: context.watch<WindowInteractionState>(),
      workspaceViewportState: context.watch<WorkspaceViewportState>(),
    );
  }

  ({
    AppUiController appUiController,
    PlatformBridge platformBridge,
    EnvironmentController environmentController,
    EnvironmentWindowHistoryController environmentWindowHistoryController,
    WorkspaceController workspaceController,
    SharedVideoControllerPool sharedVideoControllerPool,
  })
  _readDependencies(BuildContext context) {
    return (
      appUiController: context.read<AppUiController>(),
      platformBridge: context.read<PlatformBridge>(),
      environmentController: context.read<EnvironmentController>(),
      environmentWindowHistoryController: context.read<EnvironmentWindowHistoryController>(),
      workspaceController: context.read<WorkspaceController>(),
      sharedVideoControllerPool: context.read<SharedVideoControllerPool>(),
    );
  }

  WorkspaceHudViewModel _buildWorkspaceHudViewModel({
    required Workspace activeWorkspace,
    required AppUiController appUiController,
    required int selectedExposeWindowCount,
  }) {
    final mediaCounts = workspaceMediaCounts(activeWorkspace);
    return WorkspaceHudViewModel(
      imageLabel: '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}',
      videoLabel: '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}',
      linkLabel: '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}',
      isExposeMode: appUiController.isExposeMode,
      showExposeSelectionHud: appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      selectedCount: selectedExposeWindowCount,
      workspaceId: activeWorkspace.id,
      workspaceZoom: activeWorkspace.viewportZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final dependencies = _readDependencies(context);
    final environment = state.environmentStoreState.environment!;
    final openWorkspaces = deriveOpenWorkspaces(state.environmentStoreState);
    final activeWorkspace = deriveActiveWorkspace(state.environmentStoreState);
    final workspaceLoadPlan = buildWorkspaceLoadPlan(environment: environment, activeWorkspace: activeWorkspace);
    final workspaceHudViewModel = _buildWorkspaceHudViewModel(
      activeWorkspace: activeWorkspace,
      appUiController: dependencies.appUiController,
      selectedExposeWindowCount: state.windowInteractionState.selectedExposeWindowIds.length,
    );

    dependencies.sharedVideoControllerPool.syncSharedVideoControllers(
      loadPlan: workspaceLoadPlan,
      environment: environment,
    );

    return WorkspaceScreen(
      environment: environment,
      openWorkspaces: openWorkspaces,
      appUiState: state.appUiState,
      windowInteractionState: state.windowInteractionState,
      loadPlan: workspaceLoadPlan,
      sharedVideoLookup: dependencies.sharedVideoControllerPool.sharedVideoForWindow,
      actions: WorkspaceScreenActions(
        drop: WorkspaceScreenDropActions(
          setDropTargetActive: state.appUiState.setDropTargetActive,
          importFiles: dependencies.workspaceController.media.importFiles,
        ),
        viewport: WorkspaceScreenViewportActions(
          trackViewportSize: state.workspaceViewportState.setViewportSize,
          handleOptionGestureHover: dependencies.workspaceController.window.handleOptionGestureHover,
          handleWorkspacePanZoomStart: dependencies.workspaceController.viewport.handleWorkspacePanZoomStart,
          handleWorkspacePanZoomUpdate: dependencies.workspaceController.viewport.handleWorkspacePanZoomUpdate,
          handleWorkspacePanZoomEnd: dependencies.workspaceController.viewport.handleWorkspacePanZoomEnd,
        ),
        window: WorkspaceScreenWindowActions(
          focusWindow: dependencies.workspaceController.window.focusWindow,
          restorePreviousWindowZOrder: dependencies.workspaceController.window.restorePreviousWindowZOrder,
          moveWindow: dependencies.workspaceController.window.moveWindow,
          resizeWindow: dependencies.workspaceController.window.resizeWindow,
          transformWindowFromTrackpad: dependencies.workspaceController.window.transformWindowFromTrackpad,
          fitWindowToContent: dependencies.workspaceController.window.fitWindowToContent,
          setWindowZoom: dependencies.workspaceController.window.setWindowZoom,
          setVideoPosition: dependencies.workspaceController.playback.setVideoPosition,
          cycleVideoPlaybackSpeed: dependencies.workspaceController.playback.cycleVideoPlaybackSpeed,
          setWindowIntrinsicSize: dependencies.workspaceController.window.setWindowIntrinsicSize,
          isVideoWindowPaused: dependencies.workspaceController.playback.isVideoWindowPaused,
          toggleVideoPlayback: dependencies.workspaceController.playback.toggleVideoPlayback,
          toggleExpose: dependencies.appUiController.toggleExpose,
          setPinnedHoverWindow: dependencies.workspaceController.window.setPinnedHoverWindow,
          clearPinnedHoverWindow: dependencies.workspaceController.window.clearPinnedHoverWindow,
          flashWindow: (windowId) =>
              dependencies.workspaceController.window.flashWindow(windowId, mounted: context.mounted),
          toggleSelectedWindow: dependencies.environmentController.navigation.toggleSelectedWindow,
          removeWindow: dependencies.environmentWindowHistoryController.removeWindow,
          setActiveGestureWindow: dependencies.workspaceController.window.setActiveGestureWindow,
          revealAssetInFinder: dependencies.platformBridge.revealAssetInFinder,
        ),
      ),
      workspaceHud: WorkspaceHud(
        viewModel: workspaceHudViewModel,
        actions: WorkspaceHudActions(
          onToggleExpose: dependencies.appUiController.toggleExpose,
          onFitWorkspaceViewportToContent: dependencies.workspaceController.viewport.fitWorkspaceViewportToContent,
          onConfirmCollateWorkspaceWindows: dependencies.workspaceController.layout.confirmCollateWorkspaceWindows,
          onConfirmApplyExposeGridToWorkspace:
              dependencies.workspaceController.layout.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showWorkspaceLinksDialog(
            context: context,
            initialWorkspace: activeWorkspace,
            controller: dependencies.workspaceController.links,
          ),
          onClearExposeSelection: dependencies.environmentController.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) => dependencies.workspaceController.viewport.setWorkspaceViewport(
            workspaceId: workspaceId,
            zoom: zoom,
            queueThumbnail: false,
          ),
          onRefreshActiveWorkspaceThumbnail: dependencies.workspaceController.thumbnails.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }
}

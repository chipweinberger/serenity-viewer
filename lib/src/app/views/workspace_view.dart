import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
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
    WorkspaceExposeLayoutController workspaceExposeLayoutController,
    WorkspaceLinksController workspaceLinksController,
    WorkspaceLinksLauncher workspaceLinksLauncher,
    WorkspaceLinksPrompts workspaceLinksPrompts,
    ThumbnailController thumbnailController,
    WorkspaceWindowHistoryController workspaceWindowHistoryController,
    WorkspaceMediaImportController workspaceMediaImportController,
    WorkspaceWindowController workspaceWindowController,
    WorkspaceViewportSessionController workspaceViewportSessionController,
    WorkspaceCollateController workspaceCollateController,
    SharedVideoControllerPool sharedVideoControllerPool,
  })
  _readDependencies(BuildContext context) {
    return (
      appUiController: context.read<AppUiController>(),
      platformBridge: context.read<PlatformBridge>(),
      environmentController: context.read<EnvironmentController>(),
      workspaceExposeLayoutController: context.read<WorkspaceExposeLayoutController>(),
      workspaceLinksController: context.read<WorkspaceLinksController>(),
      workspaceLinksLauncher: context.read<WorkspaceLinksLauncher>(),
      workspaceLinksPrompts: context.read<WorkspaceLinksPrompts>(),
      thumbnailController: context.read<ThumbnailController>(),
      workspaceWindowHistoryController: context.read<WorkspaceWindowHistoryController>(),
      workspaceMediaImportController: context.read<WorkspaceMediaImportController>(),
      workspaceWindowController: context.read<WorkspaceWindowController>(),
      workspaceViewportSessionController: context.read<WorkspaceViewportSessionController>(),
      workspaceCollateController: context.read<WorkspaceCollateController>(),
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
      actions: WorkspaceScreenHostActions(
        setDropTargetActive: state.appUiState.setDropTargetActive,
        importFiles: dependencies.workspaceMediaImportController.importFiles,
        trackViewportSize: state.workspaceViewportState.setViewportSize,
        handleOptionGestureHover: dependencies.workspaceWindowController.handleOptionGestureHover,
        handleWorkspacePanZoomStart: dependencies.workspaceWindowController.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: dependencies.workspaceWindowController.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: dependencies.workspaceWindowController.handleWorkspacePanZoomEnd,
        focusWindow: dependencies.workspaceWindowController.focusWindow,
        restorePreviousWindowZOrder: dependencies.workspaceWindowController.restorePreviousWindowZOrder,
        moveWindow: dependencies.workspaceWindowController.moveWindow,
        resizeWindow: dependencies.workspaceWindowController.resizeWindow,
        transformWindowFromTrackpad: dependencies.workspaceWindowController.transformWindowFromTrackpad,
        fitWindowToContent: dependencies.workspaceWindowController.fitWindowToContent,
        setWindowZoom: dependencies.workspaceWindowController.setWindowZoom,
        setVideoPosition: dependencies.workspaceWindowController.setVideoPosition,
        cycleVideoPlaybackSpeed: dependencies.workspaceWindowController.cycleVideoPlaybackSpeed,
        setWindowIntrinsicSize: dependencies.workspaceWindowController.setWindowIntrinsicSize,
        isVideoWindowPaused: dependencies.workspaceWindowController.isVideoWindowPaused,
        toggleVideoPlayback: dependencies.workspaceWindowController.toggleVideoPlayback,
        toggleExpose: dependencies.appUiController.toggleExpose,
        setPinnedHoverWindow: dependencies.workspaceWindowController.setPinnedHoverWindow,
        clearPinnedHoverWindow: dependencies.workspaceWindowController.clearPinnedHoverWindow,
        flashWindow: (windowId) =>
            dependencies.workspaceWindowController.flashWindow(windowId, mounted: context.mounted),
        toggleSelectedWindow: dependencies.environmentController.navigation.toggleSelectedWindow,
        removeWindow: dependencies.workspaceWindowHistoryController.removeWindow,
        setActiveGestureWindow: dependencies.workspaceWindowController.setActiveGestureWindow,
        revealAssetInFinder: dependencies.platformBridge.revealAssetInFinder,
      ),
      workspaceHud: WorkspaceHud(
        viewModel: workspaceHudViewModel,
        actions: WorkspaceHudActions(
          onToggleExpose: dependencies.appUiController.toggleExpose,
          onFitWorkspaceViewportToContent: dependencies.workspaceWindowController.fitWorkspaceViewportToContent,
          onConfirmCollateWorkspaceWindows: dependencies.workspaceCollateController.confirmCollateWorkspaceWindows,
          onConfirmApplyExposeGridToWorkspace:
              dependencies.workspaceExposeLayoutController.confirmApplyExposeGridToWorkspace,
          onOpenLinks: () => showWorkspaceLinksDialog(
            context: context,
            initialWorkspace: activeWorkspace,
            controller: dependencies.workspaceLinksController,
            launcher: dependencies.workspaceLinksLauncher,
            prompts: dependencies.workspaceLinksPrompts,
          ),
          onClearExposeSelection: dependencies.environmentController.navigation.clearExposeSelection,
          onSetWorkspaceZoom: (workspaceId, zoom) => dependencies.workspaceViewportSessionController
              .setWorkspaceViewport(workspaceId: workspaceId, zoom: zoom, queueThumbnail: false),
          onRefreshActiveWorkspaceThumbnail: dependencies.thumbnailController.refreshActiveWorkspaceIfNeeded,
        ),
      ),
    );
  }
}

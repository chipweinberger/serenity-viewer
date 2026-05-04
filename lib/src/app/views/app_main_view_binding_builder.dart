import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';

import 'package:serenity_viewer/src/app/views/app_main_view_contract.dart';

AppMainViewModel _buildAppMainViewModel({
  required AppStateStore state,
  required int selectedExposeWindowCount,
}) {
  return AppMainViewModel(
    uiState: state.appUiState,
    environment: state.environmentStoreState.environment!,
    windowTitle: deriveWindowTitle(state),
    workspaces: deriveWorkspaces(state),
    openWorkspaces: deriveOpenWorkspaces(state),
    activeWorkspace: deriveActiveWorkspace(state),
    activeWorkspaceOrNull: deriveActiveWorkspaceOrNull(state),
    selectedExposeWindowCount: selectedExposeWindowCount,
    windowInteractionState: state.windowInteractionState,
    workspaceViewportState: state.workspaceViewportState,
  );
}

AppMainViewServices _buildAppMainViewServices({
  required AppUiController appUiController,
  required SharedVideoControllerPool sharedVideoControllerPool,
  required EnvironmentController environmentController,
  required WorkspaceExposeLayoutController workspaceExposeLayoutController,
  required WorkspaceLinksController workspaceLinksController,
  required WorkspaceLinksLauncher workspaceLinksLauncher,
  required WorkspaceLinksPrompts workspaceLinksPrompts,
  required ThumbnailController thumbnailController,
  required WorkspaceWindowHistoryController windowHistoryController,
  required AppUiHandles uiHandles,
}) {
  return AppMainViewServices(
    appUiController: appUiController,
    sharedVideoControllerPool: sharedVideoControllerPool,
    environmentController: environmentController,
    workspaceExposeLayoutController: workspaceExposeLayoutController,
    workspaceLinksController: workspaceLinksController,
    workspaceLinksLauncher: workspaceLinksLauncher,
    workspaceLinksPrompts: workspaceLinksPrompts,
    thumbnailController: thumbnailController,
    windowHistoryController: windowHistoryController,
    searchController: uiHandles.searchController,
    tabScrollController: uiHandles.tabScrollController,
  );
}

AppMainViewActions _buildAppMainViewActions({
  required AppUiController appUiController,
  required Future<void> Function(Asset asset) revealAssetInFinder,
  required WorkspaceMediaImportController workspaceMediaImportController,
  required WorkspaceWindowController workspaceWindowController,
  required WorkspaceViewportSessionController workspaceViewportSessionController,
  required WorkspaceCollateController workspaceCollateController,
  required bool Function() mounted,
}) {
  return AppMainViewActions(
    app: AppActions(
      files: AppFileActions(importFiles: workspaceMediaImportController.importFiles),
      platform: AppPlatformActions(revealAssetInFinder: revealAssetInFinder),
    ),
    window: WindowActions(
      interaction: WindowInteractionActions(
        handleOptionGestureHover: workspaceWindowController.handleOptionGestureHover,
        focusWindow: workspaceWindowController.focusWindow,
        setPinnedHoverWindow: workspaceWindowController.setPinnedHoverWindow,
        clearPinnedHoverWindow: workspaceWindowController.clearPinnedHoverWindow,
        flashWindow: (windowId) => workspaceWindowController.flashWindow(windowId, mounted: mounted()),
        setActiveGestureWindow: workspaceWindowController.setActiveGestureWindow,
      ),
      layout: WindowLayoutActions(
        restorePreviousWindowZOrder: workspaceWindowController.restorePreviousWindowZOrder,
        moveWindow: workspaceWindowController.moveWindow,
        resizeWindow: workspaceWindowController.resizeWindow,
        transformWindowFromTrackpad: workspaceWindowController.transformWindowFromTrackpad,
        fitWindowToContent: workspaceWindowController.fitWindowToContent,
        setWindowZoom: workspaceWindowController.setWindowZoom,
        setWindowIntrinsicSize: workspaceWindowController.setWindowIntrinsicSize,
      ),
      playback: WindowPlaybackActions(
        setVideoPosition: workspaceWindowController.setVideoPosition,
        cycleVideoPlaybackSpeed: workspaceWindowController.cycleVideoPlaybackSpeed,
        isVideoWindowPaused: workspaceWindowController.isVideoWindowPaused,
        toggleVideoPlayback: workspaceWindowController.toggleVideoPlayback,
      ),
    ),
    workspace: WorkspaceActions(
      viewport: WorkspaceViewportActions(
        handleWorkspacePanZoomStart: workspaceWindowController.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: workspaceWindowController.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: workspaceWindowController.handleWorkspacePanZoomEnd,
        fitWorkspaceViewportToContent: workspaceWindowController.fitWorkspaceViewportToContent,
        setWorkspaceViewport: workspaceViewportSessionController.setWorkspaceViewport,
      ),
      layout: WorkspaceLayoutActions(
        confirmCollateWorkspaceWindows: workspaceCollateController.confirmCollateWorkspaceWindows,
      ),
      mode: WorkspaceModeActions(toggleExpose: appUiController.toggleExpose),
    ),
  );
}

({
  AppMainViewModel model,
  AppMainViewServices services,
  AppMainViewActions actions,
}) buildAppMainViewBindings({
  required AppStateStore state,
  required AppUiController appUiController,
  required SharedVideoControllerPool sharedVideoControllerPool,
  required Future<void> Function(Asset asset) revealAssetInFinder,
  required WorkspaceController workspaceController,
  required EnvironmentController environmentController,
  required WorkspaceExposeLayoutController workspaceExposeLayoutController,
  required WorkspaceLinksController workspaceLinksController,
  required WorkspaceLinksLauncher workspaceLinksLauncher,
  required WorkspaceLinksPrompts workspaceLinksPrompts,
  required ThumbnailController thumbnailController,
  required WorkspaceWindowHistoryController windowHistoryController,
  required WorkspaceMediaImportController workspaceMediaImportController,
  required WorkspaceWindowController workspaceWindowController,
  required WorkspaceViewportSessionController workspaceViewportSessionController,
  required WorkspaceCollateController workspaceCollateController,
  required AppUiHandles uiHandles,
  required bool Function() mounted,
}) {
  return (
    model: _buildAppMainViewModel(
      state: state,
      selectedExposeWindowCount: workspaceController.expose.count(),
    ),
    services: _buildAppMainViewServices(
      appUiController: appUiController,
      sharedVideoControllerPool: sharedVideoControllerPool,
      environmentController: environmentController,
      workspaceExposeLayoutController: workspaceExposeLayoutController,
      workspaceLinksController: workspaceLinksController,
      workspaceLinksLauncher: workspaceLinksLauncher,
      workspaceLinksPrompts: workspaceLinksPrompts,
      thumbnailController: thumbnailController,
      windowHistoryController: windowHistoryController,
      uiHandles: uiHandles,
    ),
    actions: _buildAppMainViewActions(
      appUiController: appUiController,
      revealAssetInFinder: revealAssetInFinder,
      workspaceMediaImportController: workspaceMediaImportController,
      workspaceWindowController: workspaceWindowController,
      workspaceViewportSessionController: workspaceViewportSessionController,
      workspaceCollateController: workspaceCollateController,
      mounted: mounted,
    ),
  );
}

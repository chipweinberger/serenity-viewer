import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';

import 'package:serenity_viewer/src/app/views/app_main_view_contract.dart';

class AppMainViewBindings {
  const AppMainViewBindings({required this.model, required this.services, required this.actions});

  final AppMainViewModel model;
  final AppMainViewServices services;
  final AppMainViewActions actions;
}

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
  required AppFoundation foundation,
  required AppWorkspaceServices workspace,
  required AppUiHandles uiHandles,
}) {
  return AppMainViewServices(
    appUiController: foundation.appUiController,
    sharedVideoControllerPool: foundation.sharedVideoControllerPool,
    environmentController: workspace.environmentController,
    workspaceExposeLayoutController: workspace.workspaceExposeLayoutController,
    workspaceLinksController: workspace.workspaceLinksController,
    workspaceLinksLauncher: workspace.workspaceLinksLauncher,
    workspaceLinksPrompts: workspace.workspaceLinksPrompts,
    thumbnailController: workspace.thumbnailController,
    windowHistoryController: workspace.workspaceWindowHistoryController,
    searchController: uiHandles.searchController,
    tabScrollController: uiHandles.tabScrollController,
  );
}

AppMainViewActions _buildAppMainViewActions({
  required AppFoundation foundation,
  required AppWorkspaceServices workspace,
  required bool Function() mounted,
}) {
  final windowController = workspace.workspaceWindowController;

  return AppMainViewActions(
    app: AppActions(
      files: AppFileActions(importFiles: workspace.workspaceMediaImportController.importFiles),
      platform: AppPlatformActions(revealAssetInFinder: foundation.platformBridge.revealAssetInFinder),
    ),
    window: WindowActions(
      interaction: WindowInteractionActions(
        handleOptionGestureHover: windowController.handleOptionGestureHover,
        focusWindow: windowController.focusWindow,
        setPinnedHoverWindow: windowController.setPinnedHoverWindow,
        clearPinnedHoverWindow: windowController.clearPinnedHoverWindow,
        flashWindow: (windowId) => windowController.flashWindow(windowId, mounted: mounted()),
        setActiveGestureWindow: windowController.setActiveGestureWindow,
      ),
      layout: WindowLayoutActions(
        restorePreviousWindowZOrder: windowController.restorePreviousWindowZOrder,
        moveWindow: windowController.moveWindow,
        resizeWindow: windowController.resizeWindow,
        transformWindowFromTrackpad: windowController.transformWindowFromTrackpad,
        fitWindowToContent: windowController.fitWindowToContent,
        setWindowZoom: windowController.setWindowZoom,
        setWindowIntrinsicSize: windowController.setWindowIntrinsicSize,
      ),
      playback: WindowPlaybackActions(
        setVideoPosition: windowController.setVideoPosition,
        cycleVideoPlaybackSpeed: windowController.cycleVideoPlaybackSpeed,
        isVideoWindowPaused: windowController.isVideoWindowPaused,
        toggleVideoPlayback: windowController.toggleVideoPlayback,
      ),
    ),
    workspace: WorkspaceActions(
      viewport: WorkspaceViewportActions(
        handleWorkspacePanZoomStart: windowController.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: windowController.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: windowController.handleWorkspacePanZoomEnd,
        fitWorkspaceViewportToContent: windowController.fitWorkspaceViewportToContent,
        setWorkspaceViewport: workspace.workspaceViewportSessionController.setWorkspaceViewport,
      ),
      layout: WorkspaceLayoutActions(
        confirmCollateWorkspaceWindows: workspace.workspaceCollateController.confirmCollateWorkspaceWindows,
      ),
      mode: WorkspaceModeActions(toggleExpose: foundation.appUiController.toggleExpose),
    ),
  );
}

AppMainViewBindings buildAppMainViewBindings({
  required AppStateStore state,
  required AppFoundation foundation,
  required AppWorkspaceServices workspace,
  required AppUiHandles uiHandles,
  required bool Function() mounted,
}) {
  return AppMainViewBindings(
    model: _buildAppMainViewModel(
      state: state,
      selectedExposeWindowCount: workspace.workspaceController.expose.count(),
    ),
    services: _buildAppMainViewServices(foundation: foundation, workspace: workspace, uiHandles: uiHandles),
    actions: _buildAppMainViewActions(foundation: foundation, workspace: workspace, mounted: mounted),
  );
}

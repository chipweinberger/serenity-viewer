import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/views/app_main_view_contract.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
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

export 'package:serenity_viewer/src/app/views/app_main_view_contract.dart';

class AppMainView extends StatelessWidget {
  const AppMainView({super.key});

  AppMainViewModel _buildModel({
    required AppStateStore state,
    required WorkspaceController workspaceController,
  }) {
    return AppMainViewModel(
      uiState: state.appUiState,
      environment: state.environmentStoreState.environment!,
      windowTitle: deriveWindowTitle(state),
      workspaces: deriveWorkspaces(state),
      openWorkspaces: deriveOpenWorkspaces(state),
      activeWorkspace: deriveActiveWorkspace(state),
      activeWorkspaceOrNull: deriveActiveWorkspaceOrNull(state),
      selectedExposeWindowCount: workspaceController.expose.count(),
      windowInteractionState: state.windowInteractionState,
      workspaceViewportState: state.workspaceViewportState,
    );
  }

  AppMainViewServices _buildServices({
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

  AppMainViewActions _buildActions({
    required AppUiController appUiController,
    required PlatformBridge platformBridge,
    required WorkspaceMediaImportController workspaceMediaImportController,
    required WorkspaceWindowController workspaceWindowController,
    required WorkspaceViewportSessionController workspaceViewportSessionController,
    required WorkspaceCollateController workspaceCollateController,
    required BuildContext context,
  }) {
    return AppMainViewActions(
      app: AppActions(
        files: AppFileActions(importFiles: workspaceMediaImportController.importFiles),
        platform: AppPlatformActions(revealAssetInFinder: platformBridge.revealAssetInFinder),
      ),
      window: WindowActions(
        interaction: WindowInteractionActions(
        handleOptionGestureHover: workspaceWindowController.handleOptionGestureHover,
        focusWindow: workspaceWindowController.focusWindow,
        setPinnedHoverWindow: workspaceWindowController.setPinnedHoverWindow,
        clearPinnedHoverWindow: workspaceWindowController.clearPinnedHoverWindow,
        flashWindow: (windowId) => workspaceWindowController.flashWindow(windowId, mounted: context.mounted),
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

  int _activeScreenIndex(AppMainViewModel model) {
    return switch (model.uiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildWorkspaceScreen(
    MediaLoadPlan workspaceLoadPlan, {
    required AppMainViewModel model,
    required AppMainViewServices services,
    required AppMainViewActions actions,
  }) {
    return WorkspaceView(model: model, services: services, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildLibraryScreen(
    MediaLoadPlan workspaceLoadPlan, {
    required AppMainViewModel model,
    required AppMainViewServices services,
    required AppMainViewActions actions,
  }) {
    return LibraryView(model: model, services: services, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildWorkspaceUiOverlay({
    required AppMainViewModel model,
    required AppMainViewServices services,
  }) {
    return AppHeader(
      windowTitle: model.windowTitle,
      openWorkspaces: model.openWorkspaces,
      activeWorkspaceId: model.environment.activeWorkspaceId,
      isLibraryScreen: services.appUiController.isLibraryScreen,
      shouldMoveSelectedWindows: services.appUiController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      draggingTabWorkspaceId: model.uiState.draggingTabWorkspaceId,
      tabScrollController: services.tabScrollController,
      actions: AppTabBarActions(
        onShowWorkspaceOverview: services.environmentController.navigation.showOverview,
        onSetDraggingTabWorkspaceId: services.appUiController.setDraggingTabWorkspaceId,
        onReorderOpenWorkspace: services.environmentController.management.reorderOpen,
        onMoveSelectedExposeWindowsToWorkspace:
            services.environmentController.management.moveSelectedExposeWindowsToWorkspace,
        onSetActiveWorkspace: services.environmentController.navigation.setActiveWorkspace,
        onConfirmCloseTab: services.environmentController.management.confirmCloseTab,
        onCreateWorkspace: services.environmentController.management.create,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppStateStore>();
    final uiHandles = context.read<AppUiHandles>();
    final appUiController = context.read<AppUiController>();
    final sharedVideoControllerPool = context.read<SharedVideoControllerPool>();
    final platformBridge = context.read<PlatformBridge>();
    final environmentController = context.read<EnvironmentController>();
    final workspaceExposeLayoutController = context.read<WorkspaceExposeLayoutController>();
    final workspaceLinksController = context.read<WorkspaceLinksController>();
    final workspaceLinksLauncher = context.read<WorkspaceLinksLauncher>();
    final workspaceLinksPrompts = context.read<WorkspaceLinksPrompts>();
    final thumbnailController = context.read<ThumbnailController>();
    final windowHistoryController = context.read<WorkspaceWindowHistoryController>();
    final workspaceMediaImportController = context.read<WorkspaceMediaImportController>();
    final workspaceWindowController = context.read<WorkspaceWindowController>();
    final workspaceViewportSessionController = context.read<WorkspaceViewportSessionController>();
    final workspaceCollateController = context.read<WorkspaceCollateController>();
    final workspaceController = context.read<WorkspaceController>();

    final model = _buildModel(state: state, workspaceController: workspaceController);
    final services = _buildServices(
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
    );
    final actions = _buildActions(
      appUiController: appUiController,
      platformBridge: platformBridge,
      workspaceMediaImportController: workspaceMediaImportController,
      workspaceWindowController: workspaceWindowController,
      workspaceViewportSessionController: workspaceViewportSessionController,
      workspaceCollateController: workspaceCollateController,
      context: context,
    );
    final workspaceLoadPlan = buildWorkspaceLoadPlan(
      environment: model.environment,
      activeWorkspace: model.activeWorkspaceOrNull,
    );
    services.sharedVideoControllerPool.syncSharedVideoControllers(
      loadPlan: workspaceLoadPlan,
      environment: model.environment,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex(model),
            children: [
              _buildWorkspaceScreen(workspaceLoadPlan, model: model, services: services, actions: actions),
              _buildLibraryScreen(workspaceLoadPlan, model: model, services: services, actions: actions),
            ],
          ),
        ),
        _buildWorkspaceUiOverlay(model: model, services: services),
      ],
    );
  }
}

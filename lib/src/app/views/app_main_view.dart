import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/window/frame/window_resize_helpers.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/window/interaction/window_zoom_update.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppMainViewModel {
  const AppMainViewModel({
    required this.uiState,
    required this.environment,
    required this.windowTitle,
    required this.workspaces,
    required this.openWorkspaces,
    required this.activeWorkspace,
    required this.activeWorkspaceOrNull,
    required this.selectedExposeWindowCount,
    required this.windowInteractionState,
    required this.workspaceViewportState,
  });

  final AppUiState uiState;
  final Environment environment;
  final String windowTitle;
  final List<Workspace> workspaces;
  final List<Workspace> openWorkspaces;
  final Workspace activeWorkspace;
  final Workspace? activeWorkspaceOrNull;
  final int selectedExposeWindowCount;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
}

class AppMainViewServices {
  const AppMainViewServices({
    required this.appUiController,
    required this.sharedVideoControllerPool,
    required this.environmentController,
    required this.workspaceExposeLayoutController,
    required this.workspaceLinksController,
    required this.workspaceLinksLauncher,
    required this.workspaceLinksPrompts,
    required this.thumbnailController,
    required this.windowHistoryController,
    required this.searchController,
    required this.tabScrollController,
  });

  final AppUiController appUiController;
  final SharedVideoControllerPool sharedVideoControllerPool;
  final EnvironmentController environmentController;
  final WorkspaceExposeLayoutController workspaceExposeLayoutController;
  final WorkspaceLinksController workspaceLinksController;
  final WorkspaceLinksLauncher workspaceLinksLauncher;
  final WorkspaceLinksPrompts workspaceLinksPrompts;
  final ThumbnailController thumbnailController;
  final WorkspaceWindowHistoryController windowHistoryController;
  final TextEditingController searchController;
  final ScrollController tabScrollController;
}

class AppMainViewActions {
  const AppMainViewActions({required this.app, required this.window, required this.workspace});

  final AppMainViewAppActions app;
  final AppMainViewWindowActions window;
  final AppMainViewWorkspaceActions workspace;
}

class AppMainViewAppActions {
  const AppMainViewAppActions({
    required this.commitStateChange,
    required this.importFiles,
    required this.revealAssetInFinder,
  });

  final void Function(VoidCallback fn) commitStateChange;
  final Future<void> Function(List<XFile> files) importFiles;
  final Future<void> Function(Asset asset) revealAssetInFinder;
}

class AppMainViewWindowActions {
  const AppMainViewWindowActions({
    required this.handleOptionGestureHover,
    required this.focusWindow,
    required this.restorePreviousWindowZOrder,
    required this.moveWindow,
    required this.resizeWindow,
    required this.transformWindowFromTrackpad,
    required this.fitWindowToContent,
    required this.setWindowZoom,
    required this.setVideoPosition,
    required this.cycleVideoPlaybackSpeed,
    required this.setWindowIntrinsicSize,
    required this.isVideoWindowPaused,
    required this.toggleVideoPlayback,
    required this.setPinnedHoverWindow,
    required this.clearPinnedHoverWindow,
    required this.flashWindow,
    required this.setActiveGestureWindow,
  });

  final void Function(PointerHoverEvent event, Workspace workspace) handleOptionGestureHover;
  final ValueChanged<String> focusWindow;
  final ValueChanged<String> restorePreviousWindowZOrder;
  final void Function(String windowId, Offset delta) moveWindow;
  final void Function(String windowId, WindowResizeHandle handle, Offset delta) resizeWindow;
  final void Function(String windowId, double scaleDelta, Offset localFocalPoint) transformWindowFromTrackpad;
  final ValueChanged<String> fitWindowToContent;
  final void Function(String windowId, WindowZoomUpdate update) setWindowZoom;
  final void Function(String windowId, int positionMs) setVideoPosition;
  final ValueChanged<String> cycleVideoPlaybackSpeed;
  final void Function(String windowId, Size intrinsicSize) setWindowIntrinsicSize;
  final bool Function(String windowId) isVideoWindowPaused;
  final ValueChanged<String> toggleVideoPlayback;
  final ValueChanged<String> setPinnedHoverWindow;
  final VoidCallback clearPinnedHoverWindow;
  final ValueChanged<String> flashWindow;
  final ValueChanged<String?> setActiveGestureWindow;
}

class AppMainViewWorkspaceActions {
  const AppMainViewWorkspaceActions({
    required this.handleWorkspacePanZoomStart,
    required this.handleWorkspacePanZoomUpdate,
    required this.handleWorkspacePanZoomEnd,
    required this.toggleExpose,
    required this.fitWorkspaceViewportToContent,
    required this.confirmCollateWorkspaceWindows,
    required this.setWorkspaceViewport,
  });

  final void Function(PointerPanZoomStartEvent event, Workspace workspace) handleWorkspacePanZoomStart;
  final void Function(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize)
  handleWorkspacePanZoomUpdate;
  final VoidCallback handleWorkspacePanZoomEnd;
  final VoidCallback fitWorkspaceViewportToContent;
  final Future<void> Function() confirmCollateWorkspaceWindows;
  final void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport;
  final VoidCallback toggleExpose;
}

class AppMainView extends StatelessWidget {
  const AppMainView({super.key, required this.model, required this.services, required this.actions});

  final AppMainViewModel model;
  final AppMainViewServices services;
  final AppMainViewActions actions;

  int get _activeScreenIndex {
    return switch (model.uiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildWorkspaceScreen(MediaLoadPlan workspaceLoadPlan) {
    return WorkspaceView(model: model, services: services, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildLibraryScreen(MediaLoadPlan workspaceLoadPlan) {
    return LibraryView(model: model, services: services, actions: actions, workspaceLoadPlan: workspaceLoadPlan);
  }

  Widget _buildWorkspaceUiOverlay() {
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
            index: _activeScreenIndex,
            children: [_buildWorkspaceScreen(workspaceLoadPlan), _buildLibraryScreen(workspaceLoadPlan)],
          ),
        ),
        _buildWorkspaceUiOverlay(),
      ],
    );
  }
}

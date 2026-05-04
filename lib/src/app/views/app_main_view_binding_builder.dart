import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';

import 'package:serenity_viewer/src/app/views/app_main_view_contract.dart';

class AppMainViewBindings {
  const AppMainViewBindings({required this.model, required this.services, required this.actions});

  final AppMainViewModel model;
  final AppMainViewServices services;
  final AppMainViewActions actions;
}

class AppMainViewBindingBuilder {
  const AppMainViewBindingBuilder({
    required this.state,
    required this.derivedState,
    required this.foundation,
    required this.workspace,
    required this.uiHandles,
    required this.mounted,
  });

  final AppRuntimeState state;
  final AppDerivedState derivedState;
  final AppFoundation foundation;
  final AppWorkspaceServices workspace;
  final AppUiHandles uiHandles;
  final bool Function() mounted;

  AppUiController get _ui => foundation.appUiController;
  SharedVideoControllerPool get _videos => foundation.sharedVideoControllerPool;
  EnvironmentController get _env => workspace.environmentController;
  WorkspaceExposeLayoutController get _expose => workspace.workspaceExposeLayoutController;
  WorkspaceLinksController get _links => workspace.workspaceLinksController;
  WorkspaceLinksLauncher get _linkLauncher => workspace.workspaceLinksLauncher;
  WorkspaceLinksPrompts get _linkPrompts => workspace.workspaceLinksPrompts;
  ThumbnailController get _thumbs => workspace.thumbnailController;
  WorkspaceWindowHistoryController get _history => workspace.workspaceWindowHistoryController;
  WorkspaceWindowController get _window => workspace.workspaceWindowController;
  WorkspaceViewportSessionController get _viewport => workspace.workspaceViewportSessionController;
  WorkspaceMediaImportController get _imports => workspace.workspaceMediaImportController;
  Future<void> Function(Asset asset) get _reveal => foundation.platformBridge.revealAssetInFinder;
  int get _selectedExposeWindowCount => workspace.workspaceController.expose.count();

  AppMainViewModel _buildModel() {
    return AppMainViewModel(
      uiState: state.appUiState,
      environment: state.environmentStoreState.environment!,
      windowTitle: derivedState.windowTitle,
      workspaces: derivedState.workspaces,
      openWorkspaces: derivedState.openWorkspaces,
      activeWorkspace: derivedState.activeWorkspace,
      activeWorkspaceOrNull: derivedState.activeWorkspaceOrNull,
      selectedExposeWindowCount: _selectedExposeWindowCount,
      windowInteractionState: state.windowInteractionState,
      workspaceViewportState: state.workspaceViewportState,
    );
  }

  AppMainViewServices _buildServices() {
    return AppMainViewServices(
      appUiController: _ui,
      sharedVideoControllerPool: _videos,
      environmentController: _env,
      workspaceExposeLayoutController: _expose,
      workspaceLinksController: _links,
      workspaceLinksLauncher: _linkLauncher,
      workspaceLinksPrompts: _linkPrompts,
      thumbnailController: _thumbs,
      windowHistoryController: _history,
      searchController: uiHandles.searchController,
      tabScrollController: uiHandles.tabScrollController,
    );
  }

  AppMainViewActions _buildActions() {
    return AppMainViewActions(
      app: AppActions(
        files: AppFileActions(importFiles: _imports.importFiles),
        platform: AppPlatformActions(revealAssetInFinder: _reveal),
      ),
      window: WindowActions(
        interaction: WindowInteractionActions(
          handleOptionGestureHover: _window.handleOptionGestureHover,
          focusWindow: _window.focusWindow,
          setPinnedHoverWindow: _window.setPinnedHoverWindow,
          clearPinnedHoverWindow: _window.clearPinnedHoverWindow,
          flashWindow: (windowId) => _window.flashWindow(windowId, mounted: mounted()),
          setActiveGestureWindow: _window.setActiveGestureWindow,
        ),
        layout: WindowLayoutActions(
          restorePreviousWindowZOrder: _window.restorePreviousWindowZOrder,
          moveWindow: _window.moveWindow,
          resizeWindow: _window.resizeWindow,
          transformWindowFromTrackpad: _window.transformWindowFromTrackpad,
          fitWindowToContent: _window.fitWindowToContent,
          setWindowZoom: _window.setWindowZoom,
          setWindowIntrinsicSize: _window.setWindowIntrinsicSize,
        ),
        playback: WindowPlaybackActions(
          setVideoPosition: _window.setVideoPosition,
          cycleVideoPlaybackSpeed: _window.cycleVideoPlaybackSpeed,
          isVideoWindowPaused: _window.isVideoWindowPaused,
          toggleVideoPlayback: _window.toggleVideoPlayback,
        ),
      ),
      workspace: WorkspaceActions(
        viewport: WorkspaceViewportActions(
          handleWorkspacePanZoomStart: _window.handleWorkspacePanZoomStart,
          handleWorkspacePanZoomUpdate: _window.handleWorkspacePanZoomUpdate,
          handleWorkspacePanZoomEnd: _window.handleWorkspacePanZoomEnd,
          fitWorkspaceViewportToContent: _window.fitWorkspaceViewportToContent,
          setWorkspaceViewport: _viewport.setWorkspaceViewport,
        ),
        layout: WorkspaceLayoutActions(
          confirmCollateWorkspaceWindows: workspace.workspaceCollateController.confirmCollateWorkspaceWindows,
        ),
        mode: WorkspaceModeActions(toggleExpose: _ui.toggleExpose),
      ),
    );
  }

  AppMainViewBindings build() {
    return AppMainViewBindings(model: _buildModel(), services: _buildServices(), actions: _buildActions());
  }
}

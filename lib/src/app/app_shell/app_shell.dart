import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_content_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_environment_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_media_import_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_menu_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_navigation_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_seed_environment.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_ui_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_window_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_window_history_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_workspace_geometry_controller.dart';
import 'package:serenity_viewer/src/app/platform/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/sry_document/sry_document_coordinator.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/video_tools/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _maxRecentlyClosedWindows = 12;
  static const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'];
  static const List<String> _videoExtensions = ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'];

  final _dependencies = ShellDependencies();
  final List<RecentlyClosedWindowEntry> _recentlyClosedWindows = [];
  late final AppShellRuntime _runtime;

  ShellHandles get _handles => _runtime.handles;
  AppEnvironmentState get _persistenceState => _runtime.persistenceState;
  ChromeState get _uiState => _runtime.chromeState;
  AssetWindowInteractionState get _windowInteractionState => _runtime.dependencies.windowInteractionState;
  WorkspaceViewportState get _workspaceViewportState => _runtime.workspaceViewportState;
  ChromeController get _chromeController => _runtime.chromeController;
  SryDocumentCoordinator get _sryDocumentCoordinator => _runtime.sryDocumentCoordinator;
  MediaBridge get _mediaBridge => _runtime.mediaBridge;
  WorkspaceController get _workspaceController => _runtime.workspaceController;
  WorkspaceShellController get _workspaceShellController => _runtime.workspaceShellController;
  LinksController get _workspaceLinksController => _runtime.workspaceLinksController;
  AppShellPlatformBridge get _appShellPlatformBridge => _runtime.appShellPlatformBridge;
  EnvironmentBookmarkSynchronizer get _environmentBookmarkSynchronizer => _runtime.environmentBookmarkSynchronizer;
  EnvironmentController get _environmentController => _runtime.environmentController;
  ThumbnailController get _thumbnailController => _runtime.thumbnailController;
  VideoConversionCoordinator get _videoConversionCoordinator => _runtime.videoConversionCoordinator;

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  List<Workspace> get _workspaces => _persistenceState.environment?.workspaces ?? const [];

  List<Workspace> get _openWorkspaces => _workspaces.where((workspace) => workspace.isOpen).toList();

  Workspace? get _activeWorkspaceOrNull {
    final environment = _persistenceState.environment;
    if (environment == null || environment.workspaces.isEmpty) {
      return null;
    }

    final matches = environment.workspaces.where((workspace) => workspace.id == environment.activeWorkspaceId);
    return matches.isNotEmpty ? matches.first : environment.workspaces.first;
  }

  Workspace get _activeWorkspace {
    return _activeWorkspaceOrNull ?? (throw StateError('No active workspace is available.'));
  }

  String get _windowTitle {
    final path = _persistenceState.currentEnvironmentPath;
    final suffix = _persistenceState.hasUnsavedChanges ? ' *' : '';
    if (path == null || path.isEmpty) {
      return 'Serenity$suffix';
    }
    return '${path.split(Platform.pathSeparator).last}$suffix';
  }

  Future<void> _restoreEnvironment() async {
    if (_isRunningInWidgetTest) {
      _environmentController.restoreWidgetTestEnvironment(buildSeedEnvironment());
      return;
    }

    try {
      final lastEnvironmentPath = await _appShellPlatformBridge.loadLastEnvironmentPath();
      if (lastEnvironmentPath != null && lastEnvironmentPath.isNotEmpty && await File(lastEnvironmentPath).exists()) {
        await _sryDocumentCoordinator.loadDocumentFromPath(
          lastEnvironmentPath,
          showSuccessMessage: false,
          persistAsLastOpened: true,
        );
        return;
      }
      await _appShellPlatformBridge.storeLastEnvironmentPath(null);
    } catch (_) {
      await _appShellPlatformBridge.storeLastEnvironmentPath(null);
    }

    _environmentController.showMissingStartupState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sryDocumentCoordinator.promptForStartupDocument());
    });
  }

  Future<void> _saveEnvironment({bool force = false}) async {
    final environment = _persistenceState.environment;
    final environmentPath = _persistenceState.currentEnvironmentPath;
    if (environment == null || environmentPath == null || environmentPath.isEmpty) {
      return;
    }
    if (!force && !_persistenceState.hasUnsavedChanges) {
      return;
    }

    try {
      final sessionToSave = await _environmentBookmarkSynchronizer.synchronize(environment);
      _environmentController.applySavedEnvironment(
        originalEnvironment: environment,
        savedEnvironment: sessionToSave,
        mounted: mounted,
      );
      await _sryDocumentCoordinator.saveDocumentToPath(
        environmentPath,
        environmentOverride: sessionToSave,
        showMessageOnFailure: false,
      );
      await _appShellPlatformBridge.syncWindowTitle();
    } catch (_) {
      // Widget tests and unsupported platforms can skip local persistence.
    }
  }

  AppShellWindowHistoryController get _windowHistoryController {
    return AppShellWindowHistoryController(
      environment: () => _persistenceState.environment,
      workspaces: () => _workspaces,
      activeWorkspace: () => _activeWorkspaceOrNull,
      recentlyClosedWindows: _recentlyClosedWindows,
      workspaceController: _workspaceController,
      updateEnvironment: _environmentActions.updateEnvironment,
      replaceWorkspace: _environmentActions.replaceWorkspace,
      commitStateChange: setState,
      showMessage: _uiController.showMessage,
      showWorkspaceScreen: _navigationController.showWorkspaceScreen,
      screen: () => _uiState.screen,
      maxRecentlyClosedWindows: _AppShellState._maxRecentlyClosedWindows,
    );
  }

  AppShellWindowController get _windowController {
    return AppShellWindowController(
      context: () => context,
      mounted: () => mounted,
      chromeState: _uiState,
      environment: () => _persistenceState.environment,
      activeWorkspace: () => _activeWorkspace,
      activeWorkspaceOrNull: () => _activeWorkspaceOrNull,
      workspaceController: _workspaceController,
      showMessage: _uiController.showMessage,
    );
  }

  AppShellWorkspaceGeometryController get _workspaceGeometryController {
    return AppShellWorkspaceGeometryController(
      persistenceState: _persistenceState,
      workspaceViewportState: _workspaceViewportState,
      thumbnailController: _thumbnailController,
      replaceWorkspace: _environmentActions.replaceWorkspace,
    );
  }

  AppShellMediaImportController get _mediaImportController {
    return AppShellMediaImportController(
      imageExtensions: _AppShellState._imageExtensions,
      videoExtensions: _AppShellState._videoExtensions,
      persistenceState: _persistenceState,
      activeWorkspace: () => _activeWorkspace,
      videoConversionCoordinator: _videoConversionCoordinator,
      createFileBookmark: _appShellPlatformBridge.createFileBookmark,
      mediaBridge: _mediaBridge,
      newId: _workspaceGeometryController.newId,
      colorFromDigest: _workspaceGeometryController.colorFromDigest,
      updateEnvironment: _environmentActions.updateEnvironment,
      thumbnailController: _thumbnailController,
      showMessage: _uiController.showMessage,
    );
  }

  AppShellNavigationController get _navigationController {
    return AppShellNavigationController(chromeController: _chromeController);
  }

  AppShellUiController get _uiController {
    return AppShellUiController(
      context: () => context,
      persistenceState: _persistenceState,
      updateEnvironment: _environmentActions.updateEnvironment,
    );
  }

  AppShellEnvironmentController get _environmentActions {
    return AppShellEnvironmentController(
      environmentController: _environmentController,
      chromeController: _chromeController,
    );
  }

  List<PlatformMenuItem> _buildMenus() {
    final focusedWindow = _windowHistoryController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && _windowInteractionState.selectedExposeWindowIds.contains(focusedWindow.asset.id);

    return AppShellMenuBuilder(
      showAboutSerenity: _uiController.showAboutSerenity,
      openSettings: _uiController.openSettings,
      createEnvironment: _sryDocumentCoordinator.createDocument,
      openEnvironment: _sryDocumentCoordinator.openDocument,
      openAssets: _mediaImportController.pickAndImportAssets,
      saveEnvironment: _sryDocumentCoordinator.saveDocument,
      saveEnvironmentAs: _sryDocumentCoordinator.saveDocumentAs,
      revealAssetInFinder: _mediaBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceShellController.navigation.toggleSelectedWindow,
      fitWindowToContent: _windowController.fitWindowToContent,
      restorePreviousWindowZOrder: _windowController.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: (windowId) => _videoConversionCoordinator.convertVideoWindowToJpeg(windowId),
      closeWindow: _windowHistoryController.removeWindow,
      toggleExpose: _environmentActions.toggleExpose,
      toggleWorkspaceOverview: _workspaceShellController.navigation.toggleOverview,
      createWorkspace: _workspaceShellController.management.createWorkspace,
      switchToPreviousWorkspace: () => _workspaceShellController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceShellController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _windowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _windowController.confirmCollateWorkspaceWindows,
      pauseAllVideos: _windowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _uiController.showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceShellController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _uiController.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceShellController.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _windowHistoryController.restoreRecentlyClosedWindow,
    ).build(
      activeWorkspaceId: _persistenceState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: _recentlyClosedWindows,
    );
  }

  Widget _buildShellContent(BuildContext context) {
    if (_persistenceState.isLoading || _persistenceState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AppShellContentBuilder(
      context: context,
      uiState: _uiState,
      environment: _persistenceState.environment!,
      windowTitle: _windowTitle,
      workspaces: _workspaces,
      openWorkspaces: _openWorkspaces,
      activeWorkspace: _activeWorkspace,
      activeWorkspaceOrNull: _activeWorkspaceOrNull,
      windowInteractionState: _windowInteractionState,
      workspaceViewportState: _workspaceViewportState,
      chromeController: _chromeController,
      mediaBridge: _mediaBridge,
      workspaceShellController: _workspaceShellController,
      workspaceLinksController: _workspaceLinksController,
      thumbnailController: _thumbnailController,
      windowHistoryController: _windowHistoryController,
      searchController: _handles.searchController,
      tabScrollController: _handles.tabScrollController,
      commitStateChange: setState,
      importFiles: _mediaImportController.importFiles,
      handleOptionGestureHover: _windowController.handleOptionGestureHover,
      handleWorkspacePanZoomStart: _windowController.handleWorkspacePanZoomStart,
      handleWorkspacePanZoomUpdate: _windowController.handleWorkspacePanZoomUpdate,
      handleWorkspacePanZoomEnd: _windowController.handleWorkspacePanZoomEnd,
      focusWindow: _windowController.focusWindow,
      restorePreviousWindowZOrder: _windowController.restorePreviousWindowZOrder,
      moveWindow: _windowController.moveWindow,
      resizeWindow: _windowController.resizeWindow,
      transformWindowFromTrackpad: _windowController.transformWindowFromTrackpad,
      fitWindowToContent: _windowController.fitWindowToContent,
      setWindowZoom: _windowController.setWindowZoom,
      setVideoPosition: _windowController.setVideoPosition,
      cycleVideoPlaybackSpeed: _windowController.cycleVideoPlaybackSpeed,
      setWindowIntrinsicSize: _windowController.setWindowIntrinsicSize,
      isVideoWindowPaused: _windowController.isVideoWindowPaused,
      toggleVideoPlayback: _windowController.toggleVideoPlayback,
      toggleExpose: _environmentActions.toggleExpose,
      setPinnedHoverWindow: _windowController.setPinnedHoverWindow,
      clearPinnedHoverWindow: _windowController.clearPinnedHoverWindow,
      flashWindow: (windowId) => _windowController.flashWindow(windowId, mounted: mounted),
      setActiveGestureWindow: _windowController.setActiveGestureWindow,
      fitWorkspaceViewportToContent: _windowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _windowController.confirmCollateWorkspaceWindows,
      setWorkspaceViewport: _workspaceGeometryController.setWorkspaceViewport,
    ).build();
  }

  @override
  void initState() {
    super.initState();
    _runtime = AppShellRuntime.create(
      isRunningInWidgetTest: _isRunningInWidgetTest,
      dependencies: _dependencies,
      windowTitle: () => _windowTitle,
      context: () => context,
      mounted: () => mounted,
      commitStateChange: setState,
      showMessage: _uiController.showMessage,
      seedEnvironment: buildSeedEnvironment,
      updateEnvironment: _environmentActions.updateEnvironment,
      replaceWorkspace: _environmentActions.replaceWorkspace,
      saveEnvironment: _saveEnvironment,
      newId: _workspaceGeometryController.newId,
      colorFromDigest: _workspaceGeometryController.colorFromDigest,
      activeWorkspace: () => _activeWorkspaceOrNull,
      workspaces: () => _workspaces,
      openWorkspaces: () => _openWorkspaces,
      focusedWindowOrNull: _windowHistoryController.focusedWindowOrNull,
      setWorkspaceViewport: _workspaceGeometryController.setWorkspaceViewport,
      showWorkspaceScreen: _navigationController.showWorkspaceScreen,
      showLibraryScreen: _navigationController.showLibraryScreen,
      toggleExpose: _environmentActions.toggleExpose,
      toggleVideoPlayback: _windowController.toggleVideoPlayback,
    );
    _restoreEnvironment();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: _buildMenus(),
      child: Focus(
        focusNode: _handles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _workspaceShellController.shortcuts.onKeyEvent(event),
        child: Scaffold(body: SafeArea(top: false, child: _buildShellContent(context))),
      ),
    );
  }
}

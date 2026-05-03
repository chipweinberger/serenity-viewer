import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_scope.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_menu_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_seed_environment.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_environment_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_media_import_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_navigation_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_ui_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_window_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_window_history_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_workspace_geometry_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

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

  AppShellRuntimeStateServices get _state => _runtime.state;
  AppShellRuntimeFoundationServices get _foundation => _runtime.foundation;
  AppShellRuntimeDocumentServices get _documents => _runtime.documents;
  AppShellRuntimeWorkspaceServices get _workspaceRuntime => _runtime.workspace;

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  List<Workspace> get _workspaces => _state.persistenceState.environment?.workspaces ?? const [];

  List<Workspace> get _openWorkspaces => _workspaces.where((workspace) => workspace.isOpen).toList();

  Workspace? get _activeWorkspaceOrNull {
    final environment = _state.persistenceState.environment;
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
    final path = _state.persistenceState.currentEnvironmentPath;
    final suffix = _state.persistenceState.hasUnsavedChanges ? ' *' : '';
    if (path == null || path.isEmpty) {
      return 'Serenity$suffix';
    }
    return '${path.split(Platform.pathSeparator).last}$suffix';
  }

  Future<void> _restoreEnvironment() async {
    if (_isRunningInWidgetTest) {
      _foundation.environmentController.restoreWidgetTestEnvironment(buildSeedEnvironment());
      return;
    }

    try {
      final lastEnvironmentPath = await _foundation.appShellPlatformBridge.loadLastEnvironmentPath();
      if (lastEnvironmentPath != null && lastEnvironmentPath.isNotEmpty && await File(lastEnvironmentPath).exists()) {
        await _documents.sryDocumentCoordinator.loadDocumentFromPath(
          lastEnvironmentPath,
          showSuccessMessage: false,
          persistAsLastOpened: true,
        );
        return;
      }
      await _foundation.appShellPlatformBridge.storeLastEnvironmentPath(null);
    } catch (_) {
      await _foundation.appShellPlatformBridge.storeLastEnvironmentPath(null);
    }

    _foundation.environmentController.showMissingStartupState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_documents.sryDocumentCoordinator.promptForStartupDocument());
    });
  }

  Future<void> _saveEnvironment({bool force = false}) async {
    final environment = _state.persistenceState.environment;
    final environmentPath = _state.persistenceState.currentEnvironmentPath;
    if (environment == null || environmentPath == null || environmentPath.isEmpty) {
      return;
    }
    if (!force && !_state.persistenceState.hasUnsavedChanges) {
      return;
    }

    try {
      final sessionToSave = await _foundation.environmentBookmarkSynchronizer.synchronize(environment);
      _foundation.environmentController.applySavedEnvironment(
        originalEnvironment: environment,
        savedEnvironment: sessionToSave,
        mounted: mounted,
      );
      await _documents.sryDocumentCoordinator.saveDocumentToPath(
        environmentPath,
        environmentOverride: sessionToSave,
        showMessageOnFailure: false,
      );
      await _foundation.appShellPlatformBridge.syncWindowTitle();
    } catch (_) {
      // Widget tests and unsupported platforms can skip local persistence.
    }
  }

  AppShellWindowHistoryController get _windowHistoryController {
    return AppShellWindowHistoryController(
      environment: () => _state.persistenceState.environment,
      workspaces: () => _workspaces,
      activeWorkspace: () => _activeWorkspaceOrNull,
      recentlyClosedWindows: _recentlyClosedWindows,
      workspaceController: _workspaceRuntime.workspaceController,
      updateEnvironment: _environmentActions.updateEnvironment,
      replaceWorkspace: _environmentActions.replaceWorkspace,
      commitStateChange: setState,
      showMessage: _uiController.showMessage,
      showWorkspaceScreen: _navigationController.showWorkspaceScreen,
      screen: () => _state.chromeState.screen,
      maxRecentlyClosedWindows: _AppShellState._maxRecentlyClosedWindows,
    );
  }

  AppShellWindowController get _windowController {
    return AppShellWindowController(
      context: () => context,
      mounted: () => mounted,
      chromeState: _state.chromeState,
      environment: () => _state.persistenceState.environment,
      activeWorkspace: () => _activeWorkspace,
      activeWorkspaceOrNull: () => _activeWorkspaceOrNull,
      workspaceController: _workspaceRuntime.workspaceController,
      showMessage: _uiController.showMessage,
    );
  }

  AppShellWorkspaceGeometryController get _workspaceGeometryController {
    return AppShellWorkspaceGeometryController(
      persistenceState: _state.persistenceState,
      workspaceViewportState: _state.workspaceViewportState,
      thumbnailController: _workspaceRuntime.thumbnailController,
      replaceWorkspace: _environmentActions.replaceWorkspace,
    );
  }

  AppShellMediaImportController get _mediaImportController {
    return AppShellMediaImportController(
      imageExtensions: _AppShellState._imageExtensions,
      videoExtensions: _AppShellState._videoExtensions,
      persistenceState: _state.persistenceState,
      activeWorkspace: () => _activeWorkspace,
      videoConversionCoordinator: _workspaceRuntime.videoConversionCoordinator,
      createFileBookmark: _foundation.appShellPlatformBridge.createFileBookmark,
      mediaBridge: _foundation.mediaBridge,
      newId: _workspaceGeometryController.newId,
      colorFromDigest: _workspaceGeometryController.colorFromDigest,
      updateEnvironment: _environmentActions.updateEnvironment,
      thumbnailController: _workspaceRuntime.thumbnailController,
      showMessage: _uiController.showMessage,
    );
  }

  AppShellNavigationController get _navigationController {
    return AppShellNavigationController(chromeController: _foundation.chromeController);
  }

  AppShellUiController get _uiController {
    return AppShellUiController(
      context: () => context,
      persistenceState: _state.persistenceState,
      updateEnvironment: _environmentActions.updateEnvironment,
    );
  }

  AppShellEnvironmentController get _environmentActions {
    return AppShellEnvironmentController(
      environmentController: _foundation.environmentController,
      chromeController: _foundation.chromeController,
    );
  }

  List<PlatformMenuItem> _buildMenus() {
    final focusedWindow = _windowHistoryController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && _workspaceRuntime.workspaceController.expose.isWindowSelected(focusedWindow.asset.id);

    return AppShellMenuBuilder(
      showAboutSerenity: _uiController.showAboutSerenity,
      openSettings: _uiController.openSettings,
      createEnvironment: _documents.sryDocumentCoordinator.createDocument,
      openEnvironment: _documents.sryDocumentCoordinator.openDocument,
      openAssets: _mediaImportController.pickAndImportAssets,
      saveEnvironment: _documents.sryDocumentCoordinator.saveDocument,
      saveEnvironmentAs: _documents.sryDocumentCoordinator.saveDocumentAs,
      revealAssetInFinder: _foundation.mediaBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceRuntime.workspaceShellController.navigation.toggleSelectedWindow,
      fitWindowToContent: _windowController.fitWindowToContent,
      restorePreviousWindowZOrder: _windowController.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: (windowId) =>
          _workspaceRuntime.videoConversionCoordinator.convertVideoWindowToJpeg(windowId),
      closeWindow: _windowHistoryController.removeWindow,
      toggleExpose: _environmentActions.toggleExpose,
      toggleWorkspaceOverview: _workspaceRuntime.workspaceShellController.navigation.toggleOverview,
      createWorkspace: _workspaceRuntime.workspaceShellController.management.createWorkspace,
      switchToPreviousWorkspace: () => _workspaceRuntime.workspaceShellController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceRuntime.workspaceShellController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _windowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _windowController.confirmCollateWorkspaceWindows,
      pauseAllVideos: _windowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _uiController.showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceRuntime.workspaceShellController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _uiController.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceRuntime.workspaceShellController.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _windowHistoryController.restoreRecentlyClosedWindow,
    ).build(
      activeWorkspaceId: _state.persistenceState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: _recentlyClosedWindows,
    );
  }

  Widget _buildShellContent(BuildContext context) {
    if (_state.persistenceState.isLoading || _state.persistenceState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AppShellContentBuilder(
      state: AppShellContentState(
        context: context,
        uiState: _state.chromeState,
        environment: _state.persistenceState.environment!,
        windowTitle: _windowTitle,
        workspaces: _workspaces,
        openWorkspaces: _openWorkspaces,
        activeWorkspace: _activeWorkspace,
        activeWorkspaceOrNull: _activeWorkspaceOrNull,
        selectedExposeWindowCount: _workspaceRuntime.workspaceController.expose.selectionCount(),
        windowInteractionState: _state.windowInteractionState,
        workspaceViewportState: _state.workspaceViewportState,
        chromeController: _foundation.chromeController,
        mediaBridge: _foundation.mediaBridge,
        workspaceShellController: _workspaceRuntime.workspaceShellController,
        workspaceLinksController: _workspaceRuntime.workspaceLinksController,
        thumbnailController: _workspaceRuntime.thumbnailController,
        windowHistoryController: _windowHistoryController,
        searchController: _state.handles.searchController,
        tabScrollController: _state.handles.tabScrollController,
      ),
      actions: AppShellContentActions(
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
      ),
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
        focusNode: _state.handles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _workspaceRuntime.workspaceShellController.shortcuts.onKeyEvent(event),
        child: Scaffold(body: SafeArea(top: false, child: _buildShellContent(context))),
      ),
    );
  }
}

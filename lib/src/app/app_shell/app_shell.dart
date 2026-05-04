import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_controllers.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_derived_state.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_scope.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_menu_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_seed_environment.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';

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
  AppShellDerivedState get _derived => AppShellDerivedState(_state);
  AppShellRuntimeFoundationServices get _foundation => _runtime.foundation;
  AppShellRuntimeDocumentServices get _documents => _runtime.documents;
  AppShellRuntimeWorkspaceServices get _workspaceRuntime => _runtime.workspace;
  AppShellControllers get _controllers {
    return AppShellControllers(
      context: () => context,
      mounted: () => mounted,
      commitStateChange: setState,
      recentlyClosedWindows: _recentlyClosedWindows,
      maxRecentlyClosedWindows: _AppShellState._maxRecentlyClosedWindows,
      imageExtensions: _AppShellState._imageExtensions,
      videoExtensions: _AppShellState._videoExtensions,
      state: _state,
      derived: _derived,
      foundation: _foundation,
      documents: _documents,
      workspace: _workspaceRuntime,
    );
  }

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
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

  List<PlatformMenuItem> _buildMenus() {
    final focusedWindow = _controllers.windowHistory.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && _workspaceRuntime.workspaceController.expose.contains(focusedWindow.asset.id);

    return AppShellMenuBuilder(
      showAboutSerenity: _controllers.ui.showAboutSerenity,
      openSettings: _controllers.ui.openSettings,
      createEnvironment: _documents.sryDocumentCoordinator.createDocument,
      openEnvironment: _documents.sryDocumentCoordinator.openDocument,
      openAssets: _controllers.mediaImport.pickAndImportAssets,
      saveEnvironment: _documents.sryDocumentCoordinator.saveDocument,
      saveEnvironmentAs: _documents.sryDocumentCoordinator.saveDocumentAs,
      revealAssetInFinder: _foundation.mediaBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceRuntime.workspaceShellController.navigation.toggleSelectedWindow,
      fitWindowToContent: _controllers.window.fitWindowToContent,
      restorePreviousWindowZOrder: _controllers.window.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: (windowId) =>
          _workspaceRuntime.videoConversionCoordinator.convertVideoWindowToJpeg(windowId),
      closeWindow: _controllers.windowHistory.removeWindow,
      toggleExpose: _controllers.environment.toggleExpose,
      toggleWorkspaceOverview: _workspaceRuntime.workspaceShellController.navigation.toggleOverview,
      createWorkspace: _workspaceRuntime.workspaceShellController.management.createWorkspace,
      switchToPreviousWorkspace: () => _workspaceRuntime.workspaceShellController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceRuntime.workspaceShellController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _controllers.window.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _controllers.window.confirmCollateWorkspaceWindows,
      pauseAllVideos: _controllers.window.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _controllers.ui.showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceRuntime.workspaceShellController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _controllers.ui.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceRuntime.workspaceShellController.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _controllers.windowHistory.restoreRecentlyClosedWindow,
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
        windowTitle: _derived.windowTitle,
        workspaces: _derived.workspaces,
        openWorkspaces: _derived.openWorkspaces,
        activeWorkspace: _derived.activeWorkspace,
        activeWorkspaceOrNull: _derived.activeWorkspaceOrNull,
        selectedExposeWindowCount: _workspaceRuntime.workspaceController.expose.count(),
        windowInteractionState: _state.windowInteractionState,
        workspaceViewportState: _state.workspaceViewportState,
        chromeController: _foundation.chromeController,
        mediaBridge: _foundation.mediaBridge,
        workspaceShellController: _workspaceRuntime.workspaceShellController,
        workspaceLinksController: _workspaceRuntime.workspaceLinksController,
        thumbnailController: _workspaceRuntime.thumbnailController,
        windowHistoryController: _controllers.windowHistory,
        searchController: _state.handles.searchController,
        tabScrollController: _state.handles.tabScrollController,
      ),
      actions: AppShellContentActions(
        commitStateChange: setState,
        importFiles: _controllers.mediaImport.importFiles,
        handleOptionGestureHover: _controllers.window.handleOptionGestureHover,
        handleWorkspacePanZoomStart: _controllers.window.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: _controllers.window.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: _controllers.window.handleWorkspacePanZoomEnd,
        focusWindow: _controllers.window.focusWindow,
        restorePreviousWindowZOrder: _controllers.window.restorePreviousWindowZOrder,
        moveWindow: _controllers.window.moveWindow,
        resizeWindow: _controllers.window.resizeWindow,
        transformWindowFromTrackpad: _controllers.window.transformWindowFromTrackpad,
        fitWindowToContent: _controllers.window.fitWindowToContent,
        setWindowZoom: _controllers.window.setWindowZoom,
        setVideoPosition: _controllers.window.setVideoPosition,
        cycleVideoPlaybackSpeed: _controllers.window.cycleVideoPlaybackSpeed,
        setWindowIntrinsicSize: _controllers.window.setWindowIntrinsicSize,
        isVideoWindowPaused: _controllers.window.isVideoWindowPaused,
        toggleVideoPlayback: _controllers.window.toggleVideoPlayback,
        toggleExpose: _controllers.environment.toggleExpose,
        setPinnedHoverWindow: _controllers.window.setPinnedHoverWindow,
        clearPinnedHoverWindow: _controllers.window.clearPinnedHoverWindow,
        flashWindow: (windowId) => _controllers.window.flashWindow(windowId, mounted: mounted),
        setActiveGestureWindow: _controllers.window.setActiveGestureWindow,
        fitWorkspaceViewportToContent: _controllers.window.fitWorkspaceViewportToContent,
        confirmCollateWorkspaceWindows: _controllers.window.confirmCollateWorkspaceWindows,
        setWorkspaceViewport: _controllers.geometry.setWorkspaceViewport,
      ),
    ).build();
  }

  @override
  void initState() {
    super.initState();
    _runtime = AppShellRuntime.create(
      AppShellRuntimeConfig(
        isRunningInWidgetTest: _isRunningInWidgetTest,
        dependencies: _dependencies,
        shell: AppShellRuntimeShellConfig(
          windowTitle: () => _derived.windowTitle,
          context: () => context,
          mounted: () => mounted,
          commitStateChange: setState,
          showMessage: _controllers.ui.showMessage,
        ),
        environment: AppShellRuntimeEnvironmentConfig(
          seedEnvironment: buildSeedEnvironment,
          updateEnvironment: _controllers.environment.updateEnvironment,
          replaceWorkspace: _controllers.environment.replaceWorkspace,
          saveEnvironment: _saveEnvironment,
        ),
        workspace: AppShellRuntimeWorkspaceConfig(
          newId: _controllers.geometry.newId,
          colorFromDigest: _controllers.geometry.colorFromDigest,
          activeWorkspace: () => _derived.activeWorkspaceOrNull,
          workspaces: () => _derived.workspaces,
          openWorkspaces: () => _derived.openWorkspaces,
          focusedWindowOrNull: _controllers.windowHistory.focusedWindowOrNull,
          setWorkspaceViewport: _controllers.geometry.setWorkspaceViewport,
          showWorkspaceScreen: _controllers.navigation.showWorkspaceScreen,
          showLibraryScreen: _controllers.navigation.showLibraryScreen,
          toggleExpose: _controllers.environment.toggleExpose,
          toggleVideoPlayback: _controllers.window.toggleVideoPlayback,
        ),
      ),
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

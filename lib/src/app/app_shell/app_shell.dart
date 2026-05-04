import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime_config_builder.dart';
import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_controllers.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_derived_state.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_persistence_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_content_scope.dart';
import 'package:serenity_viewer/src/app/app_shell/builders/app_shell_menu_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_seed_environment.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
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
  late final AppShellController _controller;
  late final AppShellPersistenceController _persistence;

  AppShellRuntimeStateServices get _state => _runtime.state;
  AppShellDerivedState get _derived => AppShellDerivedState(_state);
  AppShellRuntimeFoundationServices get _foundation => _runtime.foundation;
  AppShellRuntimeDocumentServices get _documents => _runtime.documents;
  AppShellRuntimeWorkspaceServices get _workspaceRuntime => _runtime.workspace;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  List<PlatformMenuItem> _buildMenus() {
    final focusedWindow = _controller.windowHistory.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && _workspaceRuntime.workspaceController.expose.contains(focusedWindow.asset.id);

    return AppShellMenuBuilder(
      showAboutSerenity: _controller.ui.showAboutSerenity,
      openSettings: _controller.ui.openSettings,
      createEnvironment: _documents.sryDocumentCoordinator.createDocument,
      openEnvironment: _documents.sryDocumentCoordinator.openDocument,
      openAssets: _controller.mediaImport.pickAndImportAssets,
      saveEnvironment: _documents.sryDocumentCoordinator.saveDocument,
      saveEnvironmentAs: _documents.sryDocumentCoordinator.saveDocumentAs,
      revealAssetInFinder: _foundation.mediaBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceRuntime.workspaceShellController.navigation.toggleSelectedWindow,
      fitWindowToContent: _controller.window.fitWindowToContent,
      restorePreviousWindowZOrder: _controller.window.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: (windowId) =>
          _workspaceRuntime.videoConversionCoordinator.convertVideoWindowToJpeg(windowId),
      closeWindow: _controller.windowHistory.removeWindow,
      toggleExpose: _controller.chrome.toggleExpose,
      toggleWorkspaceOverview: _workspaceRuntime.workspaceShellController.navigation.toggleOverview,
      createWorkspace: _workspaceRuntime.workspaceShellController.management.create,
      switchToPreviousWorkspace: () => _workspaceRuntime.workspaceShellController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceRuntime.workspaceShellController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _controller.window.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _controller.window.confirmCollateWorkspaceWindows,
      pauseAllVideos: _controller.window.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _controller.ui.showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceRuntime.workspaceShellController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _controller.ui.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceRuntime.workspaceShellController.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _controller.windowHistory.restoreRecentlyClosedWindow,
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
        windowHistoryController: _controller.windowHistory,
        searchController: _state.handles.searchController,
        tabScrollController: _state.handles.tabScrollController,
      ),
      actions: AppShellContentActions(
        commitStateChange: setState,
        importFiles: _controller.mediaImport.importFiles,
        handleOptionGestureHover: _controller.window.handleOptionGestureHover,
        handleWorkspacePanZoomStart: _controller.window.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: _controller.window.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: _controller.window.handleWorkspacePanZoomEnd,
        focusWindow: _controller.window.focusWindow,
        restorePreviousWindowZOrder: _controller.window.restorePreviousWindowZOrder,
        moveWindow: _controller.window.moveWindow,
        resizeWindow: _controller.window.resizeWindow,
        transformWindowFromTrackpad: _controller.window.transformWindowFromTrackpad,
        fitWindowToContent: _controller.window.fitWindowToContent,
        setWindowZoom: _controller.window.setWindowZoom,
        setVideoPosition: _controller.window.setVideoPosition,
        cycleVideoPlaybackSpeed: _controller.window.cycleVideoPlaybackSpeed,
        setWindowIntrinsicSize: _controller.window.setWindowIntrinsicSize,
        isVideoWindowPaused: _controller.window.isVideoWindowPaused,
        toggleVideoPlayback: _controller.window.toggleVideoPlayback,
        toggleExpose: _controller.chrome.toggleExpose,
        setPinnedHoverWindow: _controller.window.setPinnedHoverWindow,
        clearPinnedHoverWindow: _controller.window.clearPinnedHoverWindow,
        flashWindow: (windowId) => _controller.window.flashWindow(windowId, mounted: mounted),
        setActiveGestureWindow: _controller.window.setActiveGestureWindow,
        fitWorkspaceViewportToContent: _controller.window.fitWorkspaceViewportToContent,
        confirmCollateWorkspaceWindows: _controller.window.confirmCollateWorkspaceWindows,
        setWorkspaceViewport: _controller.geometry.setWorkspaceViewport,
      ),
    ).build();
  }

  @override
  void initState() {
    super.initState();
    _runtime = AppShellRuntime.create(_buildRuntimeConfig());
    _controller = AppShellController(
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
    _persistence = AppShellPersistenceController(
      state: _state,
      foundation: _foundation,
      documents: _documents,
      mounted: () => mounted,
      seedEnvironment: buildSeedEnvironment,
      isRunningInWidgetTest: _isRunningInWidgetTest,
    );
    _persistence.restoreEnvironment();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(9999)}';
  }

  int _colorFromDigest(String value) {
    return assetColorFromMd5(value).toARGB32();
  }

  AppShellRuntimeConfig _buildRuntimeConfig() {
    return AppShellRuntimeConfigBuilder(
      dependencies: _dependencies,
      context: () => context,
      mounted: () => mounted,
      commitStateChange: setState,
      showMessage: _showMessage,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      derivedState: () => _derived,
      foundation: () => _foundation,
      controller: () => _controller,
      persistence: () => _persistence,
      newId: _newId,
      colorFromDigest: _colorFromDigest,
    ).build();
  }

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
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

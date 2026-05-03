import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/asset_import/import_coordinator.dart';
import 'package:serenity_viewer/src/asset_import/import_result.dart';
import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_menu_builder.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_window_history_controller.dart';
import 'package:serenity_viewer/src/app/platform/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/sry_document/sry_document_coordinator.dart';
import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/video_tools/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/video_tools/settings_and_video_models.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace_loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/settings/behavior/settings_dialog.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_overlay.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_view_model.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

part 'app_shell_content.dart';
part 'app_shell_environment_actions.dart';
part 'app_shell_media_import_actions.dart';
part 'app_shell_navigation_actions.dart';
part 'app_shell_startup_seed_and_settings.dart';
part 'app_shell_window_actions.dart';
part 'app_shell_workspace_geometry.dart';

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
      _environmentController.restoreWidgetTestEnvironment(_seedEnvironment());
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
      updateEnvironment: _updateEnvironment,
      replaceWorkspace: _replaceWorkspace,
      commitStateChange: setState,
      showMessage: _showMessage,
      showWorkspaceScreen: _showWorkspaceScreen,
      screen: () => _uiState.screen,
      maxRecentlyClosedWindows: _AppShellState._maxRecentlyClosedWindows,
    );
  }

  List<PlatformMenuItem> _buildMenus() {
    final focusedWindow = _windowHistoryController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && _windowInteractionState.selectedExposeWindowIds.contains(focusedWindow.asset.id);

    return AppShellMenuBuilder(
      showAboutSerenity: _showAboutSerenity,
      openSettings: _openSettings,
      createEnvironment: _sryDocumentCoordinator.createDocument,
      openEnvironment: _sryDocumentCoordinator.openDocument,
      openAssets: _pickAndImportAssets,
      saveEnvironment: _sryDocumentCoordinator.saveDocument,
      saveEnvironmentAs: _sryDocumentCoordinator.saveDocumentAs,
      revealAssetInFinder: _mediaBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceShellController.navigation.toggleSelectedWindow,
      fitWindowToContent: _fitWindowToContent,
      restorePreviousWindowZOrder: _restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: (windowId) => _videoConversionCoordinator.convertVideoWindowToJpeg(windowId),
      closeWindow: _windowHistoryController.removeWindow,
      toggleExpose: _toggleExpose,
      toggleWorkspaceOverview: _workspaceShellController.navigation.toggleOverview,
      createWorkspace: _workspaceShellController.management.createWorkspace,
      switchToPreviousWorkspace: () => _workspaceShellController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceShellController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
      pauseAllVideos: _pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceShellController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceShellController.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _windowHistoryController.restoreRecentlyClosedWindow,
    ).build(
      activeWorkspaceId: _persistenceState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: _recentlyClosedWindows,
    );
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
      showMessage: _showMessage,
      seedEnvironment: _seedEnvironment,
      updateEnvironment: _updateEnvironment,
      replaceWorkspace: _replaceWorkspace,
      saveEnvironment: _saveEnvironment,
      newId: _newId,
      colorFromDigest: _colorFromDigest,
      activeWorkspace: () => _activeWorkspaceOrNull,
      workspaces: () => _workspaces,
      openWorkspaces: () => _openWorkspaces,
      focusedWindowOrNull: _windowHistoryController.focusedWindowOrNull,
      setWorkspaceViewport: _setWorkspaceViewport,
      showWorkspaceScreen: _showWorkspaceScreen,
      showLibraryScreen: _showLibraryScreen,
      toggleExpose: _toggleExpose,
      toggleVideoPlayback: _toggleVideoPlayback,
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

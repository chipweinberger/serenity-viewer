import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/asset_import/import_coordinator.dart';
import 'package:serenity_viewer/src/asset_import/import_result.dart';
import 'package:serenity_viewer/src/app/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/app/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/sry_document_coordinator.dart';
import 'package:serenity_viewer/src/app/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/app_environment_controller.dart';
import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/video_tools/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_mutations.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/video_tools/settings_and_video_models.dart';
import 'package:serenity_viewer/src/environment/workspace_asset.dart';
import 'package:serenity_viewer/src/environment/workspace_state.dart';
import 'package:serenity_viewer/src/workspace_loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/app/app_environment_state.dart';
import 'package:serenity_viewer/src/workspace/session/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/expose/expose_layouts.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/settings/behavior/settings_dialog.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/thumbnails/workspace_thumbnail_refresher.dart';
import 'package:serenity_viewer/src/thumbnails/workspace_thumbnail_renderer.dart';
import 'package:serenity_viewer/src/thumbnails/workspace_thumbnail_store.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_overlay.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_chrome_view_model.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/screen/workspace_screen.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

part '../app/app_shell_environment_actions.dart';
part '../settings/behavior/app_shell_navigation_actions.dart';
part '../app/app_shell_window_actions.dart';
part '../app/app_shell_window_history_actions.dart';
part '../workspace/app_shell/app_shell_workspace_management_actions.dart';
part '../app/app_shell_menu_actions.dart';
part '../app/app_shell_startup_seed_and_settings.dart';
part '../workspace/app_shell/app_shell_workspace_view_tracking_actions.dart';
part '../workspace/viewport/app_shell_workspace_geometry.dart';
part '../app/app_shell_content.dart';
part '../asset_import/app_shell_media_import_actions.dart';

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
  AppLifecycleListener? _appLifecycleListener;
  Timer? _autosaveTimer;
  late final ChromeController _chromeController;
  late final SryDocumentCoordinator _sryDocumentCoordinator;
  late final MediaBridge _mediaBridge;
  late final WorkspaceController _workspaceController;
  late final WorkspaceLinksController _workspaceLinksController;
  late final AppShellPlatformBridge _appShellPlatformBridge;
  late final EnvironmentBookmarkSynchronizer _environmentBookmarkSynchronizer;
  late final EnvironmentController _environmentController;
  late final WorkspaceThumbnailRenderer _workspaceThumbnailRenderer;
  late final WorkspaceThumbnailStore _workspaceThumbnailStore;
  late final WorkspaceThumbnailRefresher _workspaceThumbnailRefresher;
  late final VideoConversionCoordinator _videoConversionCoordinator;

  ShellHandles get _handles => _dependencies.handles;
  AppEnvironmentState get _persistenceState => _dependencies.persistenceState;
  ChromeState get _uiState => _dependencies.chromeState;
  AssetWindowInteractionState get _windowInteractionState => _dependencies.windowInteractionState;
  WorkspaceViewTrackingState get _workspaceViewTrackingState => _dependencies.workspaceViewTrackingState;
  WorkspaceViewportState get _workspaceViewportState => _dependencies.workspaceViewportState;
  ThumbnailRefreshState get _thumbnailRefreshState => _dependencies.thumbnailRefreshState;

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  List<WorkspaceState> get _workspaces => _persistenceState.environment?.workspaces ?? const [];

  List<WorkspaceState> get _openWorkspaces => _workspaces.where((workspace) => workspace.isOpen).toList();

  WorkspaceState? get _activeWorkspaceOrNull {
    final environment = _persistenceState.environment;
    if (environment == null || environment.workspaces.isEmpty) {
      return null;
    }

    final matches = environment.workspaces.where((workspace) => workspace.id == environment.activeWorkspaceId);
    return matches.isNotEmpty ? matches.first : environment.workspaces.first;
  }

  WorkspaceState get _activeWorkspace {
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

  Future<void> _refreshActiveWorkspaceThumbnailIfNeeded() async {
    if (_uiState.screen != SerenityScreen.workspace) {
      return;
    }

    final workspaceId = _activeWorkspaceOrNull?.id;
    if (workspaceId == null || !_thumbnailRefreshState.dirtyWorkspaces.contains(workspaceId)) {
      return;
    }

    final viewportSize = _workspaceViewportState.viewportSize;
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return;
    }

    if (_thumbnailRefreshState.refreshInFlight.contains(workspaceId)) {
      return;
    }

    if (mounted) {
      setState(() {
        _thumbnailRefreshState.refreshInFlight.add(workspaceId);
      });
    } else {
      _thumbnailRefreshState.refreshInFlight.add(workspaceId);
    }

    try {
      await _workspaceThumbnailRefresher.refreshWorkspace(workspaceId, viewportSize: viewportSize);
    } finally {
      if (!mounted) {
        _thumbnailRefreshState.dirtyWorkspaces.remove(workspaceId);
        _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
      } else {
        setState(() {
          _thumbnailRefreshState.dirtyWorkspaces.remove(workspaceId);
          _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
        });
      }
    }
  }

  void _queueThumbnailRefresh(String workspaceId, {Duration delay = const Duration(milliseconds: 300)}) {
    _thumbnailRefreshState.debounces[workspaceId]?.cancel();
    _thumbnailRefreshState.debounces[workspaceId] = Timer(delay, () {
      _thumbnailRefreshState.dirtyWorkspaces.add(workspaceId);
      _thumbnailRefreshState.debounces.remove(workspaceId);
      unawaited(_refreshActiveWorkspaceThumbnailIfNeeded());
    });
  }

  @override
  void initState() {
    super.initState();
    _chromeController = ChromeController(
      chromeState: _uiState,
      windowInteractionState: _windowInteractionState,
      commitStateChange: setState,
      refreshWorkspaceTracking: _refreshWorkspaceViewTracking,
    );
    _mediaBridge = MediaBridge(
      isRunningInWidgetTest: _isRunningInWidgetTest,
      showMessage: _showMessage,
      isMounted: () => mounted,
    );
    _environmentController = EnvironmentController(
      persistenceState: _persistenceState,
      chromeState: _uiState,
      thumbnailRefreshState: _thumbnailRefreshState,
      commitStateChange: setState,
      refreshWorkspaceTracking: _refreshWorkspaceViewTracking,
      syncWindowTitle: () => _appShellPlatformBridge.syncWindowTitle(),
    );
    _appShellPlatformBridge = AppShellPlatformBridge(
      persistenceState: _persistenceState,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      windowTitle: () => _windowTitle,
    );
    _environmentBookmarkSynchronizer = EnvironmentBookmarkSynchronizer(
      createFileBookmark: _appShellPlatformBridge.createFileBookmark,
    );
    _workspaceThumbnailRenderer = WorkspaceThumbnailRenderer(isRunningInWidgetTest: _isRunningInWidgetTest);
    _workspaceThumbnailStore = WorkspaceThumbnailStore(thumbnailDirectory: _appShellPlatformBridge.thumbnailDirectory);
    _workspaceThumbnailRefresher = WorkspaceThumbnailRefresher(
      persistenceState: _persistenceState,
      environmentController: _environmentController,
      renderer: _workspaceThumbnailRenderer,
      store: _workspaceThumbnailStore,
    );
    _sryDocumentCoordinator = SryDocumentCoordinator(
      persistenceState: _persistenceState,
      environmentController: _environmentController,
      context: () => context,
      mounted: () => mounted,
      seedEnvironment: _seedEnvironment,
      showMessage: _showMessage,
      refreshActiveWorkspaceThumbnailIfNeeded: _refreshActiveWorkspaceThumbnailIfNeeded,
      storeLastEnvironmentPath: _appShellPlatformBridge.storeLastEnvironmentPath,
      syncWindowTitle: _appShellPlatformBridge.syncWindowTitle,
      resolveFileBookmark: _appShellPlatformBridge.resolveFileBookmark,
      createFileBookmark: _appShellPlatformBridge.createFileBookmark,
      thumbnailDirectory: _appShellPlatformBridge.thumbnailDirectory,
      updateEnvironment: _updateEnvironment,
      saveEnvironment: _saveEnvironment,
    );
    _videoConversionCoordinator = VideoConversionCoordinator(
      context: () => context,
      mounted: () => mounted,
      showMessage: _showMessage,
      mediaBridge: _mediaBridge,
      createFileBookmark: _appShellPlatformBridge.createFileBookmark,
      activeWorkspace: () => _activeWorkspaceOrNull,
      replaceWorkspace: _replaceWorkspace,
      colorFromDigest: _colorFromDigest,
      removePausedVideoWindow: (windowId) {
        setState(() {
          _windowInteractionState.pausedVideoWindows.remove(windowId);
        });
      },
    );
    _workspaceLinksController = WorkspaceLinksController(
      screen: () => _uiState.screen,
      hasSession: () => _persistenceState.environment != null,
      activeWorkspace: () => _activeWorkspaceOrNull,
      workspaces: () => _workspaces,
      replaceWorkspace: _replaceWorkspace,
      newId: _newId,
      showMessage: _showMessage,
      context: () => context,
      mounted: () => mounted,
    );
    _workspaceController = WorkspaceController(
      chromeState: _uiState,
      windowInteractionState: _windowInteractionState,
      workspaceViewportState: _workspaceViewportState,
      commitInteractionState: setState,
      replaceWorkspace: _replaceWorkspace,
      setWorkspaceViewport: _setWorkspaceViewport,
      refreshActiveWorkspaceThumbnail: _refreshActiveWorkspaceThumbnailIfNeeded,
    );
    _autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_persistenceState.hasUnsavedChanges) {
        unawaited(_saveEnvironment());
      }
    });
    _appLifecycleListener = AppLifecycleListener(
      onStateChange: _handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await _saveEnvironment(force: true);
        return ui.AppExitResponse.exit;
      },
    );
    _restoreEnvironment();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _appLifecycleListener?.dispose();
    _workspaceViewTrackingState.dispose();
    _windowInteractionState.dispose();
    _thumbnailRefreshState.dispose();
    _mediaBridge.dispose();
    _handles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: _buildMenus(),
      child: Focus(
        focusNode: _handles.focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Scaffold(body: SafeArea(top: false, child: _buildShellContent(context))),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/environments/environment_coordinator.dart';
import 'package:serenity_viewer/src/media/importing/import_coordinator.dart';
import 'package:serenity_viewer/src/media/importing/import_result.dart';
import 'package:serenity_viewer/src/media/playback/media_bridge.dart';
import 'package:serenity_viewer/src/app/shell_dependencies.dart';
import 'package:serenity_viewer/src/environments/session/session_controller.dart';
import 'package:serenity_viewer/src/environments/persistence/session_persistence_bridge.dart';
import 'package:serenity_viewer/src/environments/persistence/workspace_thumbnail_refresher.dart';
import 'package:serenity_viewer/src/environments/persistence/workspace_thumbnail_renderer.dart';
import 'package:serenity_viewer/src/environments/persistence/workspace_thumbnail_store.dart';
import 'package:serenity_viewer/src/media/conversion/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/workspace_mutations.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/workspace/windows/workspace_window_state.dart';
import 'package:serenity_viewer/src/workspace/windows/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/environments/session/session_state.dart';
import 'package:serenity_viewer/src/workspace/canvas/workspace_chrome_view_model.dart';
import 'package:serenity_viewer/src/media/conversion/settings_and_video_models.dart';
import 'package:serenity_viewer/src/workspace/windows/window_zoom_update.dart';
import 'package:serenity_viewer/src/media/assets/workspace_asset.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/environments/session/shell_persistence_state.dart';
import 'package:serenity_viewer/src/environments/persistence/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/settings/behavior/settings_dialog.dart';
import 'package:serenity_viewer/src/workspace/windows/window_resize_helpers.dart';
import 'package:serenity_viewer/src/library/library_screen.dart';
import 'package:serenity_viewer/src/workspace/canvas/workspace_chrome_overlay.dart';
import 'package:serenity_viewer/src/workspace/canvas/workspace_hud.dart';
import 'package:serenity_viewer/src/workspace/expose/expose_layouts.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_dialog.dart';
import 'package:serenity_viewer/src/workspace/canvas/workspace_screen.dart';

part '../environments/session/app_shell_session_actions.dart';
part '../settings/behavior/app_shell_navigation_actions.dart';
part '../app/app_shell_window_actions.dart';
part '../app/app_shell_window_history_actions.dart';
part '../workspace/app_shell_workspace_management_actions.dart';
part '../app/app_shell_menu_actions.dart';
part '../environments/startup/app_shell_startup_seed_and_settings.dart';
part '../workspace/app_shell_workspace_view_tracking_actions.dart';
part '../workspace/viewport/app_shell_workspace_geometry.dart';
part '../app/app_shell_content.dart';
part '../media/importing/app_shell_media_import_actions.dart';

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
  late final EnvironmentCoordinator _environmentCoordinator;
  late final MediaBridge _mediaBridge;
  late final WorkspaceController _workspaceController;
  late final WorkspaceLinksController _workspaceLinksController;
  late final SessionController _sessionController;
  late final SessionPersistenceBridge _sessionPersistenceBridge;
  late final WorkspaceThumbnailRenderer _workspaceThumbnailRenderer;
  late final WorkspaceThumbnailStore _workspaceThumbnailStore;
  late final WorkspaceThumbnailRefresher _workspaceThumbnailRefresher;
  late final VideoConversionCoordinator _videoConversionCoordinator;

  ShellHandles get _handles => _dependencies.handles;
  ShellPersistenceState get _persistenceState => _dependencies.persistenceState;
  ChromeState get _uiState => _dependencies.chromeState;
  WindowInteractionState get _windowInteractionState => _dependencies.windowInteractionState;
  WorkspaceViewTrackingState get _workspaceViewTrackingState => _dependencies.workspaceViewTrackingState;
  WorkspaceViewportState get _workspaceViewportState => _dependencies.workspaceViewportState;
  ThumbnailRefreshState get _thumbnailRefreshState => _dependencies.thumbnailRefreshState;

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  List<WorkspaceState> get _workspaces => _persistenceState.session?.workspaces ?? const [];

  List<WorkspaceState> get _openWorkspaces => _workspaces.where((workspace) => workspace.isOpen).toList();

  WorkspaceState? get _activeWorkspaceOrNull {
    final session = _persistenceState.session;
    if (session == null || session.workspaces.isEmpty) {
      return null;
    }

    final matches = session.workspaces.where((workspace) => workspace.id == session.activeWorkspaceId);
    return matches.isNotEmpty ? matches.first : session.workspaces.first;
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
    _sessionController = SessionController(
      persistenceState: _persistenceState,
      chromeState: _uiState,
      thumbnailRefreshState: _thumbnailRefreshState,
      commitStateChange: setState,
      refreshWorkspaceTracking: _refreshWorkspaceViewTracking,
      syncWindowTitle: () => _sessionPersistenceBridge.syncWindowTitle(),
    );
    _sessionPersistenceBridge = SessionPersistenceBridge(
      persistenceState: _persistenceState,
      sessionController: _sessionController,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      mounted: () => mounted,
      seedSession: _seedSession,
      environmentCoordinator: () => _environmentCoordinator,
      windowTitle: () => _windowTitle,
    );
    _workspaceThumbnailRenderer = WorkspaceThumbnailRenderer(isRunningInWidgetTest: _isRunningInWidgetTest);
    _workspaceThumbnailStore = WorkspaceThumbnailStore(
      thumbnailDirectory: _sessionPersistenceBridge.thumbnailDirectory,
    );
    _workspaceThumbnailRefresher = WorkspaceThumbnailRefresher(
      persistenceState: _persistenceState,
      sessionController: _sessionController,
      renderer: _workspaceThumbnailRenderer,
      store: _workspaceThumbnailStore,
    );
    _environmentCoordinator = EnvironmentCoordinator(
      persistenceState: _persistenceState,
      sessionController: _sessionController,
      context: () => context,
      mounted: () => mounted,
      seedSession: _seedSession,
      showMessage: _showMessage,
      refreshActiveWorkspaceThumbnailIfNeeded: _refreshActiveWorkspaceThumbnailIfNeeded,
      storeLastEnvironmentPath: _sessionPersistenceBridge.storeLastEnvironmentPath,
      syncWindowTitle: _sessionPersistenceBridge.syncWindowTitle,
      resolveFileBookmark: _sessionPersistenceBridge.resolveFileBookmark,
      createFileBookmark: _sessionPersistenceBridge.createFileBookmark,
      thumbnailDirectory: _sessionPersistenceBridge.thumbnailDirectory,
      updateSession: _updateSession,
      saveSession: _sessionPersistenceBridge.saveSession,
    );
    _videoConversionCoordinator = VideoConversionCoordinator(
      context: () => context,
      mounted: () => mounted,
      showMessage: _showMessage,
      mediaBridge: _mediaBridge,
      sessionPersistenceBridge: _sessionPersistenceBridge,
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
      hasSession: () => _persistenceState.session != null,
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
        unawaited(_sessionPersistenceBridge.saveSession());
      }
    });
    _appLifecycleListener = AppLifecycleListener(
      onStateChange: _handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await _sessionPersistenceBridge.saveSession(force: true);
        return ui.AppExitResponse.exit;
      },
    );
    _sessionPersistenceBridge.restoreSession();
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

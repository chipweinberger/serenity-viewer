import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:serenity_viewer/src/app/serenity_chrome_controller.dart';
import 'package:serenity_viewer/src/app/serenity_environment_coordinator.dart';
import 'package:serenity_viewer/src/app/serenity_import_coordinator.dart';
import 'package:serenity_viewer/src/app/serenity_import_result.dart';
import 'package:serenity_viewer/src/app/serenity_media_bridge.dart';
import 'package:serenity_viewer/src/app/serenity_shell_dependencies.dart';
import 'package:serenity_viewer/src/app/serenity_session_controller.dart';
import 'package:serenity_viewer/src/app/serenity_session_persistence_bridge.dart';
import 'package:serenity_viewer/src/app/serenity_video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/app/serenity_workspace_links_controller.dart';
import 'package:serenity_viewer/src/app/serenity_workspace_controller.dart';
import 'package:serenity_viewer/src/app/serenity_workspace_mutations.dart';
import 'package:serenity_viewer/src/core/serenity_core.dart';
import 'package:serenity_viewer/src/core/serenity_keyboard_modifiers.dart';
import 'package:serenity_viewer/src/core/serenity_theme.dart';
import 'package:serenity_viewer/src/core/serenity_workspace_projection.dart';
import 'package:serenity_viewer/src/models/asset_window_state.dart';
import 'package:serenity_viewer/src/models/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/models/serenity_session_state.dart';
import 'package:serenity_viewer/src/models/serenity_workspace_chrome_view_model.dart';
import 'package:serenity_viewer/src/models/session_support.dart';
import 'package:serenity_viewer/src/models/window_zoom_update.dart';
import 'package:serenity_viewer/src/models/workspace_asset.dart';
import 'package:serenity_viewer/src/models/workspace_state.dart';
import 'package:serenity_viewer/src/media/serenity_workspace_load_plan.dart';
import 'package:serenity_viewer/src/state/serenity_chrome_state.dart';
import 'package:serenity_viewer/src/state/serenity_shell_persistence_state.dart';
import 'package:serenity_viewer/src/state/serenity_thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/state/serenity_window_interaction_state.dart';
import 'package:serenity_viewer/src/state/serenity_workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/state/serenity_workspace_viewport_state.dart';
import 'package:serenity_viewer/src/widgets/serenity_media_zoom_utils.dart';
import 'package:serenity_viewer/src/widgets/serenity_settings_dialog.dart';
import 'package:serenity_viewer/src/widgets/window_resize_helpers.dart';
import 'package:serenity_viewer/src/views/serenity_library_screen.dart';
import 'package:serenity_viewer/src/views/serenity_workspace_chrome_overlay.dart';
import 'package:serenity_viewer/src/views/serenity_workspace_hud.dart';
import 'package:serenity_viewer/src/views/serenity_workspace_layouts.dart';
import 'package:serenity_viewer/src/views/serenity_workspace_links_dialog.dart';
import 'package:serenity_viewer/src/views/serenity_workspace_screen.dart';

part '../app/serenity_session_actions.dart';
part '../app/serenity_shell_ui_state.dart';
part '../app/serenity_window_actions.dart';
part '../app/serenity_window_history_actions.dart';
part '../app/serenity_workspace_management.dart';
part '../app/serenity_menus.dart';
part '../app/serenity_seed_and_settings.dart';
part '../app/serenity_workspace_views.dart';
part '../app/serenity_workspace_geometry.dart';
part '../views/serenity_library_view.dart';
part '../persistence/serenity_thumbnail_persistence.dart';
part '../media/serenity_import_and_load_plan.dart';

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: SerenityTheme.background,
      colorScheme: const ColorScheme.light(
        primary: SerenityTheme.accent,
        secondary: SerenityTheme.accentSoft,
        surface: SerenityTheme.panel,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: SerenityTheme.textPrimary,
        displayColor: SerenityTheme.textPrimary,
      ),
      useMaterial3: true,
    );

    return MaterialApp(title: 'Serenity', debugShowCheckedModeBanner: false, theme: theme, home: const SerenityShell());
  }
}

class SerenityShell extends StatefulWidget {
  const SerenityShell({super.key});

  @override
  State<SerenityShell> createState() => _SerenityShellState();
}

class _SerenityShellState extends State<SerenityShell> {
  static const int _maxRecentlyClosedWindows = 12;
  static const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff'];
  static const List<String> _videoExtensions = ['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'];

  final _dependencies = SerenityShellDependencies();
  final List<RecentlyClosedWindowEntry> _recentlyClosedWindows = [];
  AppLifecycleListener? _appLifecycleListener;
  Timer? _autosaveTimer;
  late final SerenityChromeController _chromeController;
  late final SerenityEnvironmentCoordinator _environmentCoordinator;
  late final SerenityMediaBridge _mediaBridge;
  late final SerenityWorkspaceController _workspaceController;
  late final SerenityWorkspaceLinksController _workspaceLinksController;
  late final SerenitySessionController _sessionController;
  late final SerenitySessionPersistenceBridge _sessionPersistenceBridge;
  late final SerenityVideoConversionCoordinator _videoConversionCoordinator;

  SerenityShellHandles get _handles => _dependencies.handles;
  SerenityShellPersistenceState get _persistenceState => _dependencies.persistenceState;
  SerenityChromeState get _uiState => _dependencies.chromeState;
  SerenityWindowInteractionState get _windowInteractionState => _dependencies.windowInteractionState;
  SerenityWorkspaceViewTrackingState get _workspaceViewTrackingState => _dependencies.workspaceViewTrackingState;
  SerenityWorkspaceViewportState get _workspaceViewportState => _dependencies.workspaceViewportState;
  SerenityThumbnailRefreshState get _thumbnailRefreshState => _dependencies.thumbnailRefreshState;

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

  @override
  void initState() {
    super.initState();
    _chromeController = SerenityChromeController(
      chromeState: _uiState,
      windowInteractionState: _windowInteractionState,
      commitStateChange: setState,
      refreshWorkspaceTracking: _refreshWorkspaceViewTracking,
    );
    _mediaBridge = SerenityMediaBridge(
      isRunningInWidgetTest: _isRunningInWidgetTest,
      showMessage: _showMessage,
      isMounted: () => mounted,
    );
    _sessionController = SerenitySessionController(
      persistenceState: _persistenceState,
      chromeState: _uiState,
      thumbnailRefreshState: _thumbnailRefreshState,
      commitStateChange: setState,
      refreshWorkspaceTracking: _refreshWorkspaceViewTracking,
      syncWindowTitle: () => _sessionPersistenceBridge.syncWindowTitle(),
    );
    _sessionPersistenceBridge = SerenitySessionPersistenceBridge(
      persistenceState: _persistenceState,
      sessionController: _sessionController,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      mounted: () => mounted,
      seedSession: _seedSession,
      environmentCoordinator: () => _environmentCoordinator,
      windowTitle: () => _windowTitle,
    );
    _environmentCoordinator = SerenityEnvironmentCoordinator(
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
    _videoConversionCoordinator = SerenityVideoConversionCoordinator(
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
    _workspaceLinksController = SerenityWorkspaceLinksController(
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
    _workspaceController = SerenityWorkspaceController(
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
        child: Scaffold(body: SafeArea(top: false, child: _buildBody(context))),
      ),
    );
  }
}

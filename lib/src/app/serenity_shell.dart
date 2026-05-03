import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/app/serenity_workspace_mutations.dart';
import 'package:serenity_viewer/src/core/serenity_core.dart';
import 'package:serenity_viewer/src/core/serenity_keyboard_modifiers.dart';
import 'package:serenity_viewer/src/core/serenity_theme.dart';
import 'package:serenity_viewer/src/core/serenity_workspace_projection.dart';
import 'package:serenity_viewer/src/models/asset_window_state.dart';
import 'package:serenity_viewer/src/models/recently_closed_window_entry.dart';
import 'package:serenity_viewer/src/models/serenity_load_plan.dart';
import 'package:serenity_viewer/src/models/serenity_session_state.dart';
import 'package:serenity_viewer/src/models/session_support.dart';
import 'package:serenity_viewer/src/models/window_zoom_update.dart';
import 'package:serenity_viewer/src/models/workspace_asset.dart';
import 'package:serenity_viewer/src/models/workspace_link.dart';
import 'package:serenity_viewer/src/models/workspace_state.dart';
import 'package:serenity_viewer/src/persistence/serenity_environment_archive.dart';
import 'package:serenity_viewer/src/media/serenity_workspace_load_plan.dart';
import 'package:serenity_viewer/src/media/serenity_import_window_planning.dart';
import 'package:serenity_viewer/src/widgets/expose_window_card.dart';
import 'package:serenity_viewer/src/widgets/serenity_media_zoom_utils.dart';
import 'package:serenity_viewer/src/widgets/serenity_settings_dialog.dart';
import 'package:serenity_viewer/src/widgets/serenity_window_frame.dart';
import 'package:serenity_viewer/src/widgets/window_resize_helpers.dart';
import 'package:serenity_viewer/src/widgets/workspace_thumbnail_card.dart';
import 'package:serenity_viewer/src/views/serenity_workspace_layouts.dart';

part '../app/serenity_session_actions.dart';
part '../app/serenity_shell_state_buckets.dart';
part '../app/serenity_shell_ui_state.dart';
part '../app/serenity_window_actions.dart';
part '../app/serenity_window_history_actions.dart';
part '../app/serenity_workspace_management.dart';
part '../app/serenity_workspace_links.dart';
part '../app/serenity_menus.dart';
part '../app/serenity_seed_and_settings.dart';
part '../app/serenity_workspace_views.dart';
part '../app/serenity_workspace_geometry.dart';
part '../views/serenity_workspace_view.dart';
part '../views/serenity_workspace_chrome.dart';
part '../views/serenity_workspace_links_dialog.dart';
part '../views/serenity_library_view.dart';
part '../persistence/serenity_startup_persistence.dart';
part '../persistence/serenity_thumbnail_persistence.dart';
part '../persistence/serenity_environment_persistence.dart';
part '../media/serenity_media_tools.dart';
part '../media/serenity_import_and_load_plan.dart';
part '../media/serenity_missing_assets.dart';
part '../media/serenity_video_conversion_tools.dart';

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

  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();

  SerenitySessionState? _session;
  String? _currentEnvironmentPath;
  bool _hasUnsavedChanges = false;

  SerenityScreen _screen = SerenityScreen.workspace;
  WorkspaceLayoutMode _workspaceLayoutMode = WorkspaceLayoutMode.freeform;
  WorkspaceSort _workspaceSort = WorkspaceSort.recentlyViewed;
  bool _isLoading = true;
  bool _editMode = false;
  bool _isDropTargetActive = false;
  bool _isPromptingForStartupEnvironment = false;
  String? _draggingTabWorkspaceId;

  final _SerenityWindowInteractionState _windowInteractionState = _SerenityWindowInteractionState();
  final List<RecentlyClosedWindowEntry> _recentlyClosedWindows = [];

  Timer? _autosaveTimer;
  final _SerenityThumbnailRefreshState _thumbnailRefreshState = _SerenityThumbnailRefreshState();
  AppLifecycleListener? _appLifecycleListener;
  final _SerenityWorkspaceViewTrackingState _workspaceViewTrackingState = _SerenityWorkspaceViewTrackingState();
  final _SerenityWorkspaceViewportState _workspaceViewportState = _SerenityWorkspaceViewportState();

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  List<WorkspaceState> get _workspaces => _session?.workspaces ?? const [];

  List<WorkspaceState> get _openWorkspaces => _workspaces.where((workspace) => workspace.isOpen).toList();

  WorkspaceState? get _activeWorkspaceOrNull {
    final session = _session;
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
    final path = _currentEnvironmentPath;
    final suffix = _hasUnsavedChanges ? ' *' : '';
    if (path == null || path.isEmpty) {
      return 'Serenity$suffix';
    }
    return '${path.split(Platform.pathSeparator).last}$suffix';
  }

  @override
  void initState() {
    super.initState();
    _autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_hasUnsavedChanges) {
        unawaited(_saveSession());
      }
    });
    _appLifecycleListener = AppLifecycleListener(
      onStateChange: _handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await _saveSession(force: true);
        return ui.AppExitResponse.exit;
      },
    );
    _restoreSession();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _appLifecycleListener?.dispose();
    _workspaceViewTrackingState.dispose();
    _windowInteractionState.dispose();
    _thumbnailRefreshState.dispose();
    for (final entry in _windowInteractionState.sharedVideoControllers.values) {
      unawaited(entry.controller.dispose());
    }
    _tabScrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: _buildMenus(),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Scaffold(body: SafeArea(top: false, child: _buildBody(context))),
      ),
    );
  }
}

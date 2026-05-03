import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

import 'package:serenity_viewer/src/environments/serenity_environment_coordinator.dart';
import 'package:serenity_viewer/src/environments/session/serenity_session_controller.dart';
import 'package:serenity_viewer/src/foundation/serenity_core.dart';
import 'package:serenity_viewer/src/workspace/windows/asset_window_state.dart';
import 'package:serenity_viewer/src/environments/session/serenity_session_state.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';
import 'package:serenity_viewer/src/environments/session/serenity_shell_persistence_state.dart';

class SerenitySessionPersistenceBridge {
  SerenitySessionPersistenceBridge({
    required this.persistenceState,
    required this.sessionController,
    required this.isRunningInWidgetTest,
    required this.mounted,
    required this.seedSession,
    required this.environmentCoordinator,
    required this.windowTitle,
  });

  final SerenityShellPersistenceState persistenceState;
  final SerenitySessionController sessionController;
  final bool isRunningInWidgetTest;
  final bool Function() mounted;
  final SerenitySessionState Function() seedSession;
  final SerenityEnvironmentCoordinator Function() environmentCoordinator;
  final String Function() windowTitle;

  Future<Directory> thumbnailDirectory() async {
    final environmentPath = persistenceState.currentEnvironmentPath ?? 'startup';
    final cacheKey = md5.convert(utf8.encode(environmentPath)).toString();
    final thumbnails = Directory('${Directory.systemTemp.path}/serenity-workspace-thumbnails/$cacheKey');
    await thumbnails.create(recursive: true);
    return thumbnails;
  }

  Future<void> restoreSession() async {
    if (isRunningInWidgetTest) {
      sessionController.restoreWidgetTestSession(seedSession());
      return;
    }

    try {
      final lastEnvironmentPath = await loadLastEnvironmentPath();
      if (lastEnvironmentPath != null && lastEnvironmentPath.isNotEmpty && await File(lastEnvironmentPath).exists()) {
        await environmentCoordinator().loadEnvironmentFromPath(
          lastEnvironmentPath,
          showSuccessMessage: false,
          persistAsLastOpened: true,
        );
        return;
      }
      await storeLastEnvironmentPath(null);
    } catch (_) {
      await storeLastEnvironmentPath(null);
    }

    sessionController.showMissingStartupState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(environmentCoordinator().promptForStartupEnvironment());
    });
  }

  Future<void> saveSession({bool force = false}) async {
    final session = persistenceState.session;
    final environmentPath = persistenceState.currentEnvironmentPath;
    if (session == null || environmentPath == null || environmentPath.isEmpty) {
      return;
    }
    if (!force && !persistenceState.hasUnsavedChanges) {
      return;
    }

    try {
      final sessionToSave = await _sessionWithRefreshedBookmarks(session);
      sessionController.applySavedSessionState(
        originalSession: session,
        savedSession: sessionToSave,
        mounted: mounted(),
      );
      await environmentCoordinator().saveEnvironmentToPath(
        environmentPath,
        sessionOverride: sessionToSave,
        showMessageOnFailure: false,
      );
      await syncWindowTitle();
    } catch (_) {
      // Widget tests and unsupported platforms can skip local persistence.
    }
  }

  Future<String?> createFileBookmark(String path) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await bookmarkChannel.invokeMethod<String>('createBookmark', {'path': path});
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveFileBookmark(String bookmark) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await bookmarkChannel.invokeMethod<String>('resolveBookmark', {'bookmark': bookmark});
    } catch (_) {
      return null;
    }
  }

  Future<void> syncWindowTitle() async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      await windowChannel.invokeMethod<void>('setWindowTitle', {'title': windowTitle()});
    } catch (_) {
      // Ignore title updates if the platform hook is unavailable.
    }
  }

  Future<String?> loadLastEnvironmentPath() async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await preferencesChannel.invokeMethod<String>('getLastEnvironmentPath');
    } catch (_) {
      return null;
    }
  }

  Future<void> storeLastEnvironmentPath(String? path) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      if (path == null || path.isEmpty) {
        await preferencesChannel.invokeMethod<void>('clearLastEnvironmentPath');
      } else {
        await preferencesChannel.invokeMethod<void>('setLastEnvironmentPath', {'path': path});
      }
    } catch (_) {
      // Ignore preferences persistence failures.
    }
  }

  Future<SerenitySessionState> _sessionWithRefreshedBookmarks(SerenitySessionState session) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return session;
    }

    var changed = false;
    final nextWorkspaces = <WorkspaceState>[];
    for (final workspace in session.workspaces) {
      final nextWindows = <AssetWindowState>[];
      for (final window in workspace.windows) {
        final asset = window.asset;
        final path = asset.filePath;
        if (path == null || path.isEmpty || asset.fileBookmark != null && asset.fileBookmark!.isNotEmpty) {
          nextWindows.add(window);
          continue;
        }

        if (!await File(path).exists()) {
          nextWindows.add(window);
          continue;
        }

        final bookmark = await createFileBookmark(path);
        if (bookmark == null || bookmark.isEmpty) {
          nextWindows.add(window);
          continue;
        }

        changed = true;
        nextWindows.add(window.copyWith(asset: asset.copyWith(fileBookmark: bookmark)));
      }
      nextWorkspaces.add(changed ? workspace.copyWith(windows: nextWindows) : workspace);
    }

    if (!changed) {
      return session;
    }

    return session.copyWith(workspaces: nextWorkspaces);
  }
}

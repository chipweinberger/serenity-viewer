// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellStartupPersistence on _SerenityShellState {
  Future<Directory> _thumbnailDirectory() async {
    final environmentPath = _persistenceState.currentEnvironmentPath ?? 'startup';
    final cacheKey = md5.convert(utf8.encode(environmentPath)).toString();
    final thumbnails = Directory('${Directory.systemTemp.path}/serenity-workspace-thumbnails/$cacheKey');
    await thumbnails.create(recursive: true);
    return thumbnails;
  }

  Future<void> _restoreSession() async {
    if (_isRunningInWidgetTest) {
      _sessionController.restoreWidgetTestSession(_seedSession());
      return;
    }

    try {
      final lastEnvironmentPath = await _loadLastEnvironmentPath();
      if (lastEnvironmentPath != null && lastEnvironmentPath.isNotEmpty && await File(lastEnvironmentPath).exists()) {
        await _environmentCoordinator.loadEnvironmentFromPath(
          lastEnvironmentPath,
          showSuccessMessage: false,
          persistAsLastOpened: true,
        );
        return;
      }
      await _storeLastEnvironmentPath(null);
    } catch (_) {
      await _storeLastEnvironmentPath(null);
    }

    _sessionController.showMissingStartupState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_environmentCoordinator.promptForStartupEnvironment());
    });
  }

  Future<SerenitySessionState> _sessionWithRefreshedBookmarks(SerenitySessionState session) async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
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

        final bookmark = await _createFileBookmark(path);
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

  Future<void> _saveSession({bool force = false}) async {
    final session = _persistenceState.session;
    final environmentPath = _persistenceState.currentEnvironmentPath;
    if (session == null || environmentPath == null || environmentPath.isEmpty) {
      return;
    }
    if (!force && !_persistenceState.hasUnsavedChanges) {
      return;
    }

    try {
      final sessionToSave = await _sessionWithRefreshedBookmarks(session);
      _sessionController.applySavedSessionState(
        originalSession: session,
        savedSession: sessionToSave,
        mounted: mounted,
      );
      await _environmentCoordinator.saveEnvironmentToPath(
        environmentPath,
        sessionOverride: sessionToSave,
        showMessageOnFailure: false,
      );
      await _syncWindowTitle();
    } catch (_) {
      // Widget tests and unsupported platforms can skip local persistence.
    }
  }

  Future<String?> _createFileBookmark(String path) async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await bookmarkChannel.invokeMethod<String>('createBookmark', {'path': path});
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveFileBookmark(String bookmark) async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await bookmarkChannel.invokeMethod<String>('resolveBookmark', {'bookmark': bookmark});
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncWindowTitle() async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      await windowChannel.invokeMethod<void>('setWindowTitle', {'title': _windowTitle});
    } catch (_) {
      // Ignore title updates if the platform hook is unavailable.
    }
  }

  Future<String?> _loadLastEnvironmentPath() async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await preferencesChannel.invokeMethod<String>('getLastEnvironmentPath');
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeLastEnvironmentPath(String? path) async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
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
}

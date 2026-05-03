// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellEnvironmentPersistence on _SerenityShellState {
  Future<void> _saveEnvironmentToPath(
    String path, {
    SerenitySessionState? sessionOverride,
    bool showMessageOnFailure = true,
  }) async {
    final session = sessionOverride ?? _persistenceState.session;
    if (session == null) {
      return;
    }

    _persistenceState.currentEnvironmentPath = path;
    try {
      await _refreshActiveWorkspaceThumbnailIfNeeded();

      final thumbnailBytesByWorkspaceId = <String, List<int>>{};
      for (final workspace in session.workspaces) {
        final thumbnailPath = workspace.thumbnailPath;
        if (thumbnailPath == null || thumbnailPath.isEmpty) {
          continue;
        }

        final thumbnailFile = File(thumbnailPath);
        if (!await thumbnailFile.exists()) {
          continue;
        }
        thumbnailBytesByWorkspaceId[workspace.id] = await thumbnailFile.readAsBytes();
      }

      final encoded = buildEnvironmentArchiveBytes(
        session: session,
        thumbnailBytesByWorkspaceId: thumbnailBytesByWorkspaceId,
      );

      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(encoded, flush: true);
      _sessionController.noteEnvironmentPathSaved(file.path, mounted: mounted);
      await _storeLastEnvironmentPath(file.path);
      await _syncWindowTitle();
    } catch (_) {
      if (showMessageOnFailure && mounted) {
        _showMessage('Serenity could not save that environment file.');
      }
      rethrow;
    }
  }

  Future<void> _saveEnvironmentAs() async {
    final location = await getSaveLocation(
      suggestedName: 'serenity-enviroment',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
      ],
    );

    if (location == null) {
      return;
    }

    try {
      await _saveEnvironmentToPath(location.path);
    } catch (_) {}
  }

  Future<void> _saveEnvironment() async {
    final path = _persistenceState.currentEnvironmentPath;
    if (path == null || path.isEmpty) {
      await _saveEnvironmentAs();
      return;
    }

    try {
      await _saveEnvironmentToPath(path);
    } catch (_) {}
  }

  Future<bool> _openEnvironment({bool showSuccessMessage = true}) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
      ],
    );

    if (file == null) {
      return false;
    }

    return _loadEnvironmentFromPath(file.path, showSuccessMessage: showSuccessMessage, persistAsLastOpened: true);
  }

  Future<bool> _loadEnvironmentFromPath(
    String path, {
    bool showSuccessMessage = true,
    bool persistAsLastOpened = true,
  }) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      final decoded = decodeEnvironmentArchiveBytes(bytes);
      final resolved = await resolveMissingAssetsInSession(
        session: decoded.session,
        resolveBookmark: _resolveFileBookmark,
        createBookmark: _createFileBookmark,
      );
      if (!mounted) {
        return false;
      }

      _sessionController.applyLoadedEnvironment(session: resolved, path: path);
      if (persistAsLastOpened) {
        await _storeLastEnvironmentPath(path);
      }
      await _restoreEnvironmentThumbnails(decoded.thumbnailBytesByWorkspaceId, resolved);
      await _saveSession();
      if (mounted && showSuccessMessage) {
        _showMessage('Opened ${path.split(Platform.pathSeparator).last}.');
      }
      return true;
    } catch (_) {
      if (mounted) {
        _showMessage('Serenity could not open that .sry environment.');
      }
      return false;
    }
  }

  Future<bool> _createEnvironment() async {
    final location = await getSaveLocation(
      suggestedName: 'serenity-enviroment',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
      ],
    );

    if (location == null) {
      return false;
    }

    final seeded = _seedSession();
    if (!mounted) {
      return false;
    }

    _sessionController.applyCreatedEnvironment(session: seeded, path: location.path);
    await _saveEnvironmentToPath(location.path, sessionOverride: seeded);
    if (!mounted) {
      return false;
    }
    _showMessage('Created ${location.path.split(Platform.pathSeparator).last}.');
    return true;
  }

  Future<void> _promptForStartupEnvironment() async {
    if (!_sessionController.shouldPromptForStartupEnvironment(mounted: mounted)) {
      return;
    }

    _sessionController.setStartupPromptInProgress(true);
    try {
      while (mounted && _persistenceState.session == null) {
        if (!mounted) {
          return;
        }
        final choice = await showDialog<StartupEnvironmentChoice>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Choose an environment'),
              content: const Text(
                'Serenity always works inside a .sry environment. Open an existing one or create a new one.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(StartupEnvironmentChoice.open),
                  child: const Text('Open Existing'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(StartupEnvironmentChoice.create),
                  child: const Text('Create New'),
                ),
              ],
            );
          },
        );

        if (choice == StartupEnvironmentChoice.open) {
          final opened = await _openEnvironment(showSuccessMessage: false);
          if (opened) {
            return;
          }
          continue;
        }

        if (choice == StartupEnvironmentChoice.create) {
          final created = await _createEnvironment();
          if (created) {
            return;
          }
          continue;
        }
      }
    } finally {
      _sessionController.setStartupPromptInProgress(false);
    }
  }

  Future<void> _restoreEnvironmentThumbnails(
    Map<String, List<int>> thumbnailBytesByWorkspaceId,
    SerenitySessionState session,
  ) async {
    final thumbnailDirectory = await _thumbnailDirectory();
    final nextWorkspaces = <WorkspaceState>[];
    var updated = false;

    for (final workspace in session.workspaces) {
      final thumbnailBytes = thumbnailBytesByWorkspaceId[workspace.id];
      if (thumbnailBytes == null) {
        nextWorkspaces.add(workspace);
        continue;
      }

      final file = File('${thumbnailDirectory.path}/${workspace.id}.jpg');
      await file.writeAsBytes(thumbnailBytes, flush: true);
      await FileImage(file).evict();
      nextWorkspaces.add(workspace.copyWith(thumbnailPath: file.path));
      updated = true;
    }

    if (updated && mounted && _persistenceState.session != null) {
      _updateSession(_persistenceState.session!.copyWith(workspaces: nextWorkspaces));
    }
  }
}

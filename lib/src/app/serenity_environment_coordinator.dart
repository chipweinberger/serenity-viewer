import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/serenity_session_controller.dart';
import 'package:serenity_viewer/src/media/serenity_missing_asset_resolution.dart';
import 'package:serenity_viewer/src/models/serenity_session_state.dart';
import 'package:serenity_viewer/src/models/session_support.dart';
import 'package:serenity_viewer/src/models/workspace_state.dart';
import 'package:serenity_viewer/src/persistence/serenity_environment_archive.dart';
import 'package:serenity_viewer/src/state/serenity_shell_persistence_state.dart';

class SerenityEnvironmentCoordinator {
  SerenityEnvironmentCoordinator({
    required this.persistenceState,
    required this.sessionController,
    required this.context,
    required this.mounted,
    required this.seedSession,
    required this.showMessage,
    required this.refreshActiveWorkspaceThumbnailIfNeeded,
    required this.storeLastEnvironmentPath,
    required this.syncWindowTitle,
    required this.resolveFileBookmark,
    required this.createFileBookmark,
    required this.thumbnailDirectory,
    required this.updateSession,
    required this.saveSession,
  });

  final SerenityShellPersistenceState persistenceState;
  final SerenitySessionController sessionController;
  final BuildContext Function() context;
  final bool Function() mounted;
  final SerenitySessionState Function() seedSession;
  final ValueChanged<String> showMessage;
  final Future<void> Function() refreshActiveWorkspaceThumbnailIfNeeded;
  final Future<void> Function(String? path) storeLastEnvironmentPath;
  final Future<void> Function() syncWindowTitle;
  final Future<String?> Function(String bookmark) resolveFileBookmark;
  final Future<String?> Function(String path) createFileBookmark;
  final Future<Directory> Function() thumbnailDirectory;
  final ValueChanged<SerenitySessionState> updateSession;
  final Future<void> Function() saveSession;

  Future<void> saveEnvironmentToPath(
    String path, {
    SerenitySessionState? sessionOverride,
    bool showMessageOnFailure = true,
  }) async {
    final session = sessionOverride ?? persistenceState.session;
    if (session == null) {
      return;
    }

    persistenceState.currentEnvironmentPath = path;
    try {
      await refreshActiveWorkspaceThumbnailIfNeeded();

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
      sessionController.noteEnvironmentPathSaved(file.path, mounted: mounted());
      await storeLastEnvironmentPath(file.path);
      await syncWindowTitle();
    } catch (_) {
      if (showMessageOnFailure && mounted()) {
        showMessage('Serenity could not save that environment file.');
      }
      rethrow;
    }
  }

  Future<void> saveEnvironmentAs() async {
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
      await saveEnvironmentToPath(location.path);
    } catch (_) {}
  }

  Future<void> saveEnvironment() async {
    final path = persistenceState.currentEnvironmentPath;
    if (path == null || path.isEmpty) {
      await saveEnvironmentAs();
      return;
    }

    try {
      await saveEnvironmentToPath(path);
    } catch (_) {}
  }

  Future<bool> openEnvironment({bool showSuccessMessage = true}) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
      ],
    );

    if (file == null) {
      return false;
    }

    return loadEnvironmentFromPath(file.path, showSuccessMessage: showSuccessMessage, persistAsLastOpened: true);
  }

  Future<bool> loadEnvironmentFromPath(
    String path, {
    bool showSuccessMessage = true,
    bool persistAsLastOpened = true,
  }) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      final decoded = decodeEnvironmentArchiveBytes(bytes);
      final resolved = await resolveMissingAssetsInSession(
        session: decoded.session,
        resolveBookmark: resolveFileBookmark,
        createBookmark: createFileBookmark,
      );
      if (!mounted()) {
        return false;
      }

      sessionController.applyLoadedEnvironment(session: resolved, path: path);
      if (persistAsLastOpened) {
        await storeLastEnvironmentPath(path);
      }
      await restoreEnvironmentThumbnails(decoded.thumbnailBytesByWorkspaceId, resolved);
      await saveSession();
      if (mounted() && showSuccessMessage) {
        showMessage('Opened ${path.split(Platform.pathSeparator).last}.');
      }
      return true;
    } catch (_) {
      if (mounted()) {
        showMessage('Serenity could not open that .sry environment.');
      }
      return false;
    }
  }

  Future<bool> createEnvironment() async {
    final location = await getSaveLocation(
      suggestedName: 'serenity-enviroment',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
      ],
    );

    if (location == null) {
      return false;
    }

    final seeded = seedSession();
    if (!mounted()) {
      return false;
    }

    sessionController.applyCreatedEnvironment(session: seeded, path: location.path);
    await saveEnvironmentToPath(location.path, sessionOverride: seeded);
    if (!mounted()) {
      return false;
    }
    showMessage('Created ${location.path.split(Platform.pathSeparator).last}.');
    return true;
  }

  Future<void> promptForStartupEnvironment() async {
    if (!sessionController.shouldPromptForStartupEnvironment(mounted: mounted())) {
      return;
    }

    sessionController.setStartupPromptInProgress(true);
    try {
      while (mounted() && persistenceState.session == null) {
        if (!mounted()) {
          return;
        }
        final choice = await showDialog<StartupEnvironmentChoice>(
          context: context(),
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
          final opened = await openEnvironment(showSuccessMessage: false);
          if (opened) {
            return;
          }
          continue;
        }

        if (choice == StartupEnvironmentChoice.create) {
          final created = await createEnvironment();
          if (created) {
            return;
          }
          continue;
        }
      }
    } finally {
      sessionController.setStartupPromptInProgress(false);
    }
  }

  Future<void> restoreEnvironmentThumbnails(
    Map<String, List<int>> thumbnailBytesByWorkspaceId,
    SerenitySessionState session,
  ) async {
    final thumbnailDir = await thumbnailDirectory();
    final nextWorkspaces = <WorkspaceState>[];
    var updated = false;

    for (final workspace in session.workspaces) {
      final thumbnailBytes = thumbnailBytesByWorkspaceId[workspace.id];
      if (thumbnailBytes == null) {
        nextWorkspaces.add(workspace);
        continue;
      }

      final file = File('${thumbnailDir.path}/${workspace.id}.jpg');
      await file.writeAsBytes(thumbnailBytes, flush: true);
      await FileImage(file).evict();
      nextWorkspaces.add(workspace.copyWith(thumbnailPath: file.path));
      updated = true;
    }

    if (updated && mounted() && persistenceState.session != null) {
      updateSession(persistenceState.session!.copyWith(workspaces: nextWorkspaces));
    }
  }
}

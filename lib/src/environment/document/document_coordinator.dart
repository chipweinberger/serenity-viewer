import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/document/document_codec.dart';
import 'package:serenity_viewer/src/environment/document/document_missing_asset_resolver.dart';
import 'package:serenity_viewer/src/environment/document/startup_environment_choice.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

const suggestedDocumentName = 'serenity-enviroment';
const documentTypeGroups = [
  XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
];

class DocumentUiActions {
  const DocumentUiActions({required this.context, required this.mounted, required this.showMessage});

  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
}

class DocumentLoadActions {
  const DocumentLoadActions({
    required this.resolveFileBookmark,
    required this.createFileBookmark,
    required this.storeLastEnvironmentPath,
    required this.saveEnvironment,
  });

  final Future<String?> Function(String bookmark) resolveFileBookmark;
  final Future<String?> Function(String path) createFileBookmark;
  final Future<void> Function(String? path) storeLastEnvironmentPath;
  final Future<void> Function() saveEnvironment;
}

class DocumentSaveActions {
  const DocumentSaveActions({
    required this.refreshActiveWorkspaceThumbnailIfNeeded,
    required this.storeLastEnvironmentPath,
    required this.syncWindowTitle,
  });

  final Future<void> Function() refreshActiveWorkspaceThumbnailIfNeeded;
  final Future<void> Function(String? path) storeLastEnvironmentPath;
  final Future<void> Function() syncWindowTitle;
}

class DocumentCreationActions {
  const DocumentCreationActions({required this.seedEnvironment});

  final Environment Function() seedEnvironment;
}

class DocumentThumbnailActions {
  const DocumentThumbnailActions({required this.thumbnailDirectory});

  final Future<Directory> Function() thumbnailDirectory;
}

class DocumentCoordinator {
  DocumentCoordinator({
    required this.environmentStore,
    required this.ui,
    required this.load,
    required this.save,
    required this.creation,
    required this.thumbnails,
  });

  final EnvironmentStore environmentStore;
  final DocumentUiActions ui;
  final DocumentLoadActions load;
  final DocumentSaveActions save;
  final DocumentCreationActions creation;
  final DocumentThumbnailActions thumbnails;

  Future<void> saveDocumentToPath(String path, {Environment? environmentOverride, bool showMessageOnFailure = true}) {
    return _saveDocumentToPath(
      path,
      environmentOverride: environmentOverride,
      showMessageOnFailure: showMessageOnFailure,
    );
  }

  Future<void> saveDocumentAs() {
    return _saveDocumentAs();
  }

  Future<void> saveDocument() {
    return _saveDocument();
  }

  Future<bool> openDocument({bool showSuccessMessage = true}) {
    return _openDocument(showSuccessMessage: showSuccessMessage);
  }

  Future<bool> loadDocumentFromPath(String path, {bool showSuccessMessage = true, bool persistAsLastOpened = true}) {
    return _loadDocumentFromPath(
      path,
      showSuccessMessage: showSuccessMessage,
      persistAsLastOpened: persistAsLastOpened,
    );
  }

  Future<bool> createDocument() {
    return _createDocument();
  }

  Future<void> promptForStartupDocument() {
    return _promptForStartupDocument();
  }

  Future<void> restoreDocumentThumbnails(Map<String, List<int>> thumbnailBytesByWorkspaceId, Environment environment) {
    return _restoreDocumentThumbnails(thumbnailBytesByWorkspaceId, environment);
  }

  Future<bool> _openDocument({required bool showSuccessMessage}) async {
    final file = await openFile(acceptedTypeGroups: documentTypeGroups);
    if (file == null) {
      return false;
    }

    return _loadDocumentFromPath(file.path, showSuccessMessage: showSuccessMessage, persistAsLastOpened: true);
  }

  Future<bool> _loadDocumentFromPath(
    String path, {
    required bool showSuccessMessage,
    required bool persistAsLastOpened,
  }) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      final decoded = decodeDocumentBytes(bytes);
      final resolved = await resolveDocumentMissingAssets(
        environment: decoded.environment,
        resolveBookmark: load.resolveFileBookmark,
        createBookmark: load.createFileBookmark,
      );
      if (!ui.mounted()) {
        return false;
      }

      environmentStore.applyLoadedEnvironment(environment: resolved, path: path);
      if (persistAsLastOpened) {
        await load.storeLastEnvironmentPath(path);
      }
      await _restoreDocumentThumbnails(decoded.thumbnailBytesByWorkspaceId, resolved);
      await load.saveEnvironment();
      if (ui.mounted() && showSuccessMessage) {
        ui.showMessage('Opened ${path.split(Platform.pathSeparator).last}.');
      }
      return true;
    } catch (_) {
      if (ui.mounted()) {
        ui.showMessage('Serenity could not open that .sry environment.');
      }
      return false;
    }
  }

  Future<bool> _createDocument() async {
    final location = await getSaveLocation(
      suggestedName: suggestedDocumentName,
      acceptedTypeGroups: documentTypeGroups,
    );
    if (location == null) {
      return false;
    }

    final seeded = creation.seedEnvironment();
    if (!ui.mounted()) {
      return false;
    }

    environmentStore.applyCreatedEnvironment(environment: seeded, path: location.path);
    await _saveDocumentToPath(location.path, environmentOverride: seeded, showMessageOnFailure: true);
    if (!ui.mounted()) {
      return false;
    }

    ui.showMessage('Created ${location.path.split(Platform.pathSeparator).last}.');
    return true;
  }

  Future<void> _promptForStartupDocument() async {
    if (!environmentStore.shouldPromptForStartupEnvironment(mounted: ui.mounted())) {
      return;
    }

    environmentStore.setStartupPromptInProgress(true);
    try {
      while (ui.mounted() && environmentStore.environmentStoreState.environment == null) {
        if (!ui.mounted()) {
          return;
        }

        final choice = await showDialog<StartupEnvironmentChoice>(
          context: ui.context(),
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
          final opened = await _openDocument(showSuccessMessage: false);
          if (opened) {
            return;
          }
          continue;
        }

        if (choice == StartupEnvironmentChoice.create) {
          final created = await _createDocument();
          if (created) {
            return;
          }
        }
      }
    } finally {
      environmentStore.setStartupPromptInProgress(false);
    }
  }

  Future<void> _saveDocumentToPath(
    String path, {
    Environment? environmentOverride,
    required bool showMessageOnFailure,
  }) async {
    final environment = environmentOverride ?? environmentStore.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    environmentStore.environmentStoreState.update(currentEnvironmentPath: path);
    try {
      await save.refreshActiveWorkspaceThumbnailIfNeeded();

      final thumbnailBytesByWorkspaceId = <String, List<int>>{};
      for (final workspace in environment.workspaces) {
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

      final encoded = encodeDocumentBytes(
        environment: environment,
        thumbnailBytesByWorkspaceId: thumbnailBytesByWorkspaceId,
      );

      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(encoded, flush: true);
      environmentStore.noteEnvironmentPathSaved(file.path, mounted: ui.mounted());
      await save.storeLastEnvironmentPath(file.path);
      await save.syncWindowTitle();
    } catch (_) {
      if (showMessageOnFailure && ui.mounted()) {
        ui.showMessage('Serenity could not save that environment file.');
      }
      rethrow;
    }
  }

  Future<void> _saveDocumentAs() async {
    final location = await getSaveLocation(
      suggestedName: suggestedDocumentName,
      acceptedTypeGroups: documentTypeGroups,
    );
    if (location == null) {
      return;
    }

    try {
      await _saveDocumentToPath(location.path, showMessageOnFailure: true);
    } catch (_) {}
  }

  Future<void> _saveDocument() async {
    final path = environmentStore.environmentStoreState.currentEnvironmentPath;
    if (path == null || path.isEmpty) {
      await _saveDocumentAs();
      return;
    }

    try {
      await _saveDocumentToPath(path, showMessageOnFailure: true);
    } catch (_) {}
  }

  Future<void> _restoreDocumentThumbnails(
    Map<String, List<int>> thumbnailBytesByWorkspaceId,
    Environment environment,
  ) async {
    final thumbnailDir = await thumbnails.thumbnailDirectory();
    final nextWorkspaces = <Workspace>[];
    var updated = false;

    for (final workspace in environment.workspaces) {
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

    if (updated && ui.mounted() && environmentStore.environmentStoreState.environment != null) {
      environmentStore.updateEnvironment(
        environmentStore.environmentStoreState.environment!.copyWith(workspaces: nextWorkspaces),
      );
    }
  }
}

part of 'document_coordinator.dart';

class _DocumentSaver {
  Future<void> saveDocumentToPath(
    DocumentCoordinator coordinator,
    String path, {
    Environment? environmentOverride,
    required bool showMessageOnFailure,
  }) async {
    final environment = environmentOverride ?? coordinator.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    coordinator.environmentStoreState.currentEnvironmentPath = path;
    try {
      await coordinator.refreshActiveWorkspaceThumbnailIfNeeded();

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
      coordinator.environmentStore.noteEnvironmentPathSaved(file.path, mounted: coordinator.mounted());
      await coordinator.storeLastEnvironmentPath(file.path);
      await coordinator.syncWindowTitle();
    } catch (_) {
      if (showMessageOnFailure && coordinator.mounted()) {
        coordinator.showMessage('Serenity could not save that environment file.');
      }
      rethrow;
    }
  }

  Future<void> saveDocumentAs(DocumentCoordinator coordinator) async {
    final location = await getSaveLocation(
      suggestedName: DocumentCoordinator._suggestedDocumentName,
      acceptedTypeGroups: DocumentCoordinator._documentTypeGroups,
    );
    if (location == null) {
      return;
    }

    try {
      await saveDocumentToPath(coordinator, location.path, showMessageOnFailure: true);
    } catch (_) {}
  }

  Future<void> saveDocument(DocumentCoordinator coordinator) async {
    final path = coordinator.environmentStoreState.currentEnvironmentPath;
    if (path == null || path.isEmpty) {
      await saveDocumentAs(coordinator);
      return;
    }

    try {
      await saveDocumentToPath(coordinator, path, showMessageOnFailure: true);
    } catch (_) {}
  }
}

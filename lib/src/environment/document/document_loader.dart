part of 'document_coordinator.dart';

class _DocumentLoader {
  Future<bool> openDocument(DocumentCoordinator coordinator, {required bool showSuccessMessage}) async {
    final file = await openFile(acceptedTypeGroups: DocumentCoordinator._documentTypeGroups);
    if (file == null) {
      return false;
    }

    return loadDocumentFromPath(
      coordinator,
      file.path,
      showSuccessMessage: showSuccessMessage,
      persistAsLastOpened: true,
    );
  }

  Future<bool> loadDocumentFromPath(
    DocumentCoordinator coordinator,
    String path, {
    required bool showSuccessMessage,
    required bool persistAsLastOpened,
  }) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      final decoded = decodeDocumentBytes(bytes);
      final resolved = await resolveDocumentMissingAssets(
        environment: decoded.environment,
        resolveBookmark: coordinator.resolveFileBookmark,
        createBookmark: coordinator.createFileBookmark,
      );
      if (!coordinator.mounted()) {
        return false;
      }

      coordinator.environmentStore.applyLoadedEnvironment(environment: resolved, path: path);
      if (persistAsLastOpened) {
        await coordinator.storeLastEnvironmentPath(path);
      }
      await coordinator.restoreDocumentThumbnails(decoded.thumbnailBytesByWorkspaceId, resolved);
      await coordinator.saveEnvironment();
      if (coordinator.mounted() && showSuccessMessage) {
        coordinator.showMessage('Opened ${path.split(Platform.pathSeparator).last}.');
      }
      return true;
    } catch (_) {
      if (coordinator.mounted()) {
        coordinator.showMessage('Serenity could not open that .sry environment.');
      }
      return false;
    }
  }

  Future<bool> createDocument(DocumentCoordinator coordinator) async {
    final location = await getSaveLocation(
      suggestedName: DocumentCoordinator._suggestedDocumentName,
      acceptedTypeGroups: DocumentCoordinator._documentTypeGroups,
    );
    if (location == null) {
      return false;
    }

    final seeded = coordinator.seedEnvironment();
    if (!coordinator.mounted()) {
      return false;
    }

    coordinator.environmentStore.applyCreatedEnvironment(environment: seeded, path: location.path);
    await coordinator.saveDocumentToPath(location.path, environmentOverride: seeded);
    if (!coordinator.mounted()) {
      return false;
    }

    coordinator.showMessage('Created ${location.path.split(Platform.pathSeparator).last}.');
    return true;
  }
}

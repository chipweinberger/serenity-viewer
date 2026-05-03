part of 'sry_document_coordinator.dart';

class _SryDocumentLoader {
  Future<bool> openDocument(SryDocumentCoordinator coordinator, {required bool showSuccessMessage}) async {
    final file = await openFile(acceptedTypeGroups: SryDocumentCoordinator._documentTypeGroups);
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
    SryDocumentCoordinator coordinator,
    String path, {
    required bool showSuccessMessage,
    required bool persistAsLastOpened,
  }) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      final decoded = decodeSryDocumentBytes(bytes);
      final resolved = await resolveMissingAssetsInEnvironment(
        environment: decoded.environment,
        resolveBookmark: coordinator.resolveFileBookmark,
        createBookmark: coordinator.createFileBookmark,
      );
      if (!coordinator.mounted()) {
        return false;
      }

      coordinator.environmentController.applyLoadedEnvironment(environment: resolved, path: path);
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

  Future<bool> createDocument(SryDocumentCoordinator coordinator) async {
    final location = await getSaveLocation(
      suggestedName: SryDocumentCoordinator._suggestedDocumentName,
      acceptedTypeGroups: SryDocumentCoordinator._documentTypeGroups,
    );
    if (location == null) {
      return false;
    }

    final seeded = coordinator.seedEnvironment();
    if (!coordinator.mounted()) {
      return false;
    }

    coordinator.environmentController.applyCreatedEnvironment(environment: seeded, path: location.path);
    await coordinator.saveDocumentToPath(location.path, environmentOverride: seeded);
    if (!coordinator.mounted()) {
      return false;
    }

    coordinator.showMessage('Created ${location.path.split(Platform.pathSeparator).last}.');
    return true;
  }
}

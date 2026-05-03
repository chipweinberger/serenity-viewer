part of 'sry_document_coordinator.dart';

class _SryDocumentThumbnailRestorer {
  Future<void> restoreDocumentThumbnails(
    SryDocumentCoordinator coordinator,
    Map<String, List<int>> thumbnailBytesByWorkspaceId,
    Environment environment,
  ) async {
    final thumbnailDir = await coordinator.thumbnailDirectory();
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

    if (updated && coordinator.mounted() && coordinator.persistenceState.environment != null) {
      coordinator.updateEnvironment(coordinator.persistenceState.environment!.copyWith(workspaces: nextWorkspaces));
    }
  }
}

import 'dart:io';

import 'package:flutter/painting.dart';

import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

Future<void> restoreDocumentThumbnails(
  DocumentCoordinator coordinator,
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

  if (updated && coordinator.mounted() && coordinator.environmentStoreState.environment != null) {
    coordinator.updateEnvironment(
      coordinator.environmentStoreState.environment!.copyWith(workspaces: nextWorkspaces),
    );
  }
}

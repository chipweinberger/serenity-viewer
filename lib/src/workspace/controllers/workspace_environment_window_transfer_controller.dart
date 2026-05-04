import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/mutations/workspace_environment_mutations.dart';

class WorkspaceEnvironmentWindowTransferController {
  const WorkspaceEnvironmentWindowTransferController();

  bool canMoveToWorkspace({
    required Environment? environment,
    required Workspace? sourceWorkspace,
    required String destinationWorkspaceId,
    required bool hasWindowIds,
  }) {
    return environment != null &&
        sourceWorkspace != null &&
        hasWindowIds &&
        destinationWorkspaceId != sourceWorkspace.id;
  }

  void moveWindowsToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
    required Set<String> windowIds,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
    required VoidCallback clearSelection,
    bool recenterMovedWindows = false,
  }) {
    updateEnvironment(
      WorkspaceEnvironmentMutations.moveWindowsToWorkspace(
        environment,
        sourceWorkspaceId: sourceWorkspace.id,
        destinationWorkspaceId: destinationWorkspace.id,
        windowIds: windowIds,
        recenterMovedWindows: recenterMovedWindows,
      ),
    );
    queueThumbnailRefresh(sourceWorkspace.id, delay: Duration.zero);
    queueThumbnailRefresh(destinationWorkspace.id, delay: Duration.zero);
    clearSelection();
  }
}

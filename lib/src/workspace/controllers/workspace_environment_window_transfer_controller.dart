import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/mutations/workspace_environment_mutations.dart';

class WorkspaceEnvironmentWindowTransferController {
  const WorkspaceEnvironmentWindowTransferController();

  bool canMoveSelectedToWorkspace({
    required Environment? environment,
    required Workspace? sourceWorkspace,
    required String destinationWorkspaceId,
    required bool hasSelectedWindowIds,
  }) {
    return environment != null &&
        sourceWorkspace != null &&
        hasSelectedWindowIds &&
        destinationWorkspaceId != sourceWorkspace.id;
  }

  void moveSelectedToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
    required Set<String> selectedWindowIds,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
    required VoidCallback clearExposeSelection,
  }) {
    updateEnvironment(
      WorkspaceEnvironmentMutations.moveSelectedWindowsToWorkspace(
        environment,
        sourceWorkspaceId: sourceWorkspace.id,
        destinationWorkspaceId: destinationWorkspace.id,
        selectedWindowIds: selectedWindowIds,
      ),
    );
    queueThumbnailRefresh(sourceWorkspace.id, delay: Duration.zero);
    queueThumbnailRefresh(destinationWorkspace.id, delay: Duration.zero);
    clearExposeSelection();
  }
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_environment_tabs.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_environment_window_transfer.dart';

class WorkspaceEnvironmentControllerState {
  WorkspaceEnvironmentControllerState()
    : tabs = const WorkspaceEnvironmentTabsState(),
      windowTransfer = const WorkspaceEnvironmentWindowTransferState();

  final WorkspaceEnvironmentTabsState tabs;
  final WorkspaceEnvironmentWindowTransferState windowTransfer;

  bool canMoveSelectedWindowsToWorkspace({
    required Environment? environment,
    required Workspace? sourceWorkspace,
    required String destinationWorkspaceId,
    required bool hasSelectedWindowIds,
  }) {
    return windowTransfer.canMoveSelectedWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspaceId: destinationWorkspaceId,
      hasSelectedWindowIds: hasSelectedWindowIds,
    );
  }

  void toggleWorkspaceOpen(Environment environment, String workspaceId, void Function(Environment) updateEnvironment) {
    tabs.toggleWorkspaceOpen(environment, workspaceId, updateEnvironment);
  }

  void reorderOpenWorkspace(
    Environment? environment,
    List<Workspace> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required void Function(Environment) updateEnvironment,
  }) {
    tabs.reorderOpenWorkspace(
      environment,
      workspaces,
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      updateEnvironment: updateEnvironment,
    );
  }

  void moveSelectedExposeWindowsToWorkspace({
    required Environment environment,
    required Workspace sourceWorkspace,
    required Workspace destinationWorkspace,
    required Set<String> selectedWindowIds,
    required void Function(Environment) updateEnvironment,
    required void Function(String workspaceId, {Duration delay}) queueThumbnailRefresh,
    required VoidCallback clearExposeSelection,
  }) {
    windowTransfer.moveSelectedExposeWindowsToWorkspace(
      environment: environment,
      sourceWorkspace: sourceWorkspace,
      destinationWorkspace: destinationWorkspace,
      selectedWindowIds: selectedWindowIds,
      updateEnvironment: updateEnvironment,
      queueThumbnailRefresh: queueThumbnailRefresh,
      clearExposeSelection: clearExposeSelection,
    );
  }
}

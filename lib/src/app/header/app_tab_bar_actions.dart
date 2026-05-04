import 'package:flutter/material.dart';

@immutable
class AppTabBarActions {
  const AppTabBarActions({
    required this.onShowWorkspaceOverview,
    required this.onSetDraggingTabWorkspaceId,
    required this.onReorderOpenWorkspace,
    required this.onMoveSelectedExposeWindowsToWorkspace,
    required this.onSetActiveWorkspace,
    required this.onConfirmCloseTab,
    required this.onCreateWorkspace,
  });

  final VoidCallback onShowWorkspaceOverview;
  final ValueChanged<String?> onSetDraggingTabWorkspaceId;
  final void Function(String sourceWorkspaceId, String targetWorkspaceId) onReorderOpenWorkspace;
  final Future<void> Function(String workspaceId) onMoveSelectedExposeWindowsToWorkspace;
  final Future<void> Function(String workspaceId) onSetActiveWorkspace;
  final Future<void> Function(String workspaceId) onConfirmCloseTab;
  final VoidCallback onCreateWorkspace;
}

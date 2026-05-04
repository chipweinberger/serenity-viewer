import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_theme.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/shared_widgets/glass_chip.dart';

class AppTab extends StatelessWidget {
  const AppTab({
    super.key,
    required this.workspace,
    required this.activeWorkspaceId,
    required this.isLibraryScreen,
    required this.shouldMoveSelectedWindows,
    required this.draggingTabWorkspaceId,
    required this.isDropTarget,
    required this.onMoveSelectedExposeWindowsToWorkspace,
    required this.onSetActiveWorkspace,
    required this.onConfirmCloseTab,
  });

  final Workspace workspace;
  final String activeWorkspaceId;
  final bool isLibraryScreen;
  final bool shouldMoveSelectedWindows;
  final String? draggingTabWorkspaceId;
  final bool isDropTarget;
  final Future<void> Function(String workspaceId) onMoveSelectedExposeWindowsToWorkspace;
  final Future<void> Function(String workspaceId) onSetActiveWorkspace;
  final Future<void> Function(String workspaceId) onConfirmCloseTab;

  bool get _isSelected {
    return !isLibraryScreen && workspace.id == activeWorkspaceId;
  }

  void _handleTap() {
    if (shouldMoveSelectedWindows) {
      unawaited(onMoveSelectedExposeWindowsToWorkspace(workspace.id));
      return;
    }
    unawaited(onSetActiveWorkspace(workspace.id));
  }

  void _handleCloseTap() {
    unawaited(onConfirmCloseTab(workspace.id));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isDropTarget ? 1.04 : 1,
      child: Opacity(
        opacity: draggingTabWorkspaceId == workspace.id ? 0.7 : 1,
        child: GlassChip(
          selected: _isSelected,
          onTap: _handleTap,
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleCloseTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 14, color: _isSelected ? Colors.white : AppTheme.textMuted),
              ),
            ),
          ),
          child: Text(workspace.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

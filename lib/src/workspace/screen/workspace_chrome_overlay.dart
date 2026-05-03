import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/appearance/glass_chip.dart';

@immutable
class WorkspaceChromeOverlayActions {
  const WorkspaceChromeOverlayActions({
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

class WorkspaceChromeOverlay extends StatelessWidget {
  const WorkspaceChromeOverlay({
    super.key,
    required this.windowTitle,
    required this.openWorkspaces,
    required this.activeWorkspaceId,
    required this.isLibraryScreen,
    required this.shouldMoveSelectedWindows,
    required this.draggingTabWorkspaceId,
    required this.tabScrollController,
    required this.actions,
  });

  final String windowTitle;
  final List<Workspace> openWorkspaces;
  final String activeWorkspaceId;
  final bool isLibraryScreen;
  final bool shouldMoveSelectedWindows;
  final String? draggingTabWorkspaceId;
  final ScrollController tabScrollController;
  final WorkspaceChromeOverlayActions actions;

  Widget _buildWindowTitleLabel(BuildContext context) {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DefaultTextStyle(
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
          child: Text(windowTitle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildWorkspaceTabChip(BuildContext context, Workspace workspace, {required bool isDropTarget}) {
    final isSelected = !isLibraryScreen && workspace.id == activeWorkspaceId;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isDropTarget ? 1.04 : 1,
      child: Opacity(
        opacity: draggingTabWorkspaceId == workspace.id ? 0.7 : 1,
        child: GlassChip(
          selected: isSelected,
          onTap: () {
            if (shouldMoveSelectedWindows) {
              unawaited(actions.onMoveSelectedExposeWindowsToWorkspace(workspace.id));
              return;
            }
            unawaited(actions.onSetActiveWorkspace(workspace.id));
          },
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => unawaited(actions.onConfirmCloseTab(workspace.id)),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 14, color: isSelected ? Colors.white : AppTheme.textMuted),
              ),
            ),
          ),
          child: Text(workspace.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  Widget _buildWorkspaceTabBar(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        controller: tabScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GlassChip(
              selected: isLibraryScreen,
              onTap: actions.onShowWorkspaceOverview,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.dashboard_outlined, size: 15), SizedBox(width: 6), Text('View All')],
              ),
            ),
            for (final workspace in openWorkspaces)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) => details.data != workspace.id,
                  onAcceptWithDetails: (details) => actions.onReorderOpenWorkspace(details.data, workspace.id),
                  builder: (context, candidateData, rejectedData) {
                    final isDropTarget = candidateData.isNotEmpty;
                    return Draggable<String>(
                      data: workspace.id,
                      maxSimultaneousDrags: 1,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      onDragStarted: () => actions.onSetDraggingTabWorkspaceId(workspace.id),
                      onDragEnd: (_) => actions.onSetDraggingTabWorkspaceId(null),
                      onDraggableCanceled: (_, __) => actions.onSetDraggingTabWorkspaceId(null),
                      feedback: Material(
                        color: Colors.transparent,
                        child: _buildWorkspaceTabChip(context, workspace, isDropTarget: false),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _buildWorkspaceTabChip(context, workspace, isDropTarget: isDropTarget),
                      ),
                      child: _buildWorkspaceTabChip(context, workspace, isDropTarget: isDropTarget),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GlassChip(onTap: actions.onCreateWorkspace, child: const Icon(Icons.add_rounded, size: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 84,
          child: AbsorbPointer(absorbing: true, child: ColoredBox(color: Colors.transparent)),
        ),
        Positioned(left: 18, right: 18, top: 28, child: _buildWorkspaceTabBar(context)),
        Positioned(top: 10, left: 120, right: 120, child: Center(child: _buildWindowTitleLabel(context))),
      ],
    );
  }
}

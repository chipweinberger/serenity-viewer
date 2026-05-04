import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/header/app_tab.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/shared_widgets/glass_chip.dart';

class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.openWorkspaces,
    required this.activeWorkspaceId,
    required this.isLibraryScreen,
    required this.shouldMoveSelectedWindows,
    required this.draggingTabWorkspaceId,
    required this.tabScrollController,
    required this.actions,
  });

  final List<Workspace> openWorkspaces;
  final String activeWorkspaceId;
  final bool isLibraryScreen;
  final bool shouldMoveSelectedWindows;
  final String? draggingTabWorkspaceId;
  final ScrollController tabScrollController;
  final AppTabBarActions actions;

  Widget _buildWorkspaceTabDragTarget(BuildContext context, Workspace workspace) {
    return DragTarget<String>(
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
            child: AppTab(
              workspace: workspace,
              activeWorkspaceId: activeWorkspaceId,
              isLibraryScreen: isLibraryScreen,
              shouldMoveSelectedWindows: shouldMoveSelectedWindows,
              draggingTabWorkspaceId: draggingTabWorkspaceId,
              isDropTarget: false,
              actions: actions,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: AppTab(
              workspace: workspace,
              activeWorkspaceId: activeWorkspaceId,
              isLibraryScreen: isLibraryScreen,
              shouldMoveSelectedWindows: shouldMoveSelectedWindows,
              draggingTabWorkspaceId: draggingTabWorkspaceId,
              isDropTarget: isDropTarget,
              actions: actions,
            ),
          ),
          child: AppTab(
            workspace: workspace,
            activeWorkspaceId: activeWorkspaceId,
            isLibraryScreen: isLibraryScreen,
            shouldMoveSelectedWindows: shouldMoveSelectedWindows,
            draggingTabWorkspaceId: draggingTabWorkspaceId,
            isDropTarget: isDropTarget,
            actions: actions,
          ),
        );
      },
    );
  }

  Widget _buildOverviewChip() {
    return GlassChip(
      selected: isLibraryScreen,
      onTap: actions.onShowWorkspaceOverview,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.dashboard_outlined, size: 15), SizedBox(width: 6), Text('View All')],
      ),
    );
  }

  Widget _buildAddWorkspaceChip() {
    return GlassChip(onTap: actions.onCreateWorkspace, child: const Icon(Icons.add_rounded, size: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        controller: tabScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildOverviewChip(),
            for (final workspace in openWorkspaces)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _buildWorkspaceTabDragTarget(context, workspace),
              ),
            Padding(padding: const EdgeInsets.only(left: 10), child: _buildAddWorkspaceChip()),
          ],
        ),
      ),
    );
  }
}

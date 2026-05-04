import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/header/app_tab.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
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
    required this.windowDragTargetWorkspaceId,
    required this.tabScrollController,
    required this.uiHandles,
    required this.onShowWorkspaceOverview,
    required this.onSetDraggingTabWorkspaceId,
    required this.onReorderOpenWorkspace,
    required this.onMoveSelectedExposeWindowsToWorkspace,
    required this.onSetActiveWorkspace,
    required this.onConfirmCloseTab,
    required this.onCreateWorkspace,
  });

  final List<Workspace> openWorkspaces;
  final String activeWorkspaceId;
  final bool isLibraryScreen;
  final bool shouldMoveSelectedWindows;
  final String? draggingTabWorkspaceId;
  final String? windowDragTargetWorkspaceId;
  final ScrollController tabScrollController;
  final AppUiHandles uiHandles;
  final VoidCallback onShowWorkspaceOverview;
  final ValueChanged<String?> onSetDraggingTabWorkspaceId;
  final void Function(String sourceWorkspaceId, String targetWorkspaceId) onReorderOpenWorkspace;
  final Future<void> Function(String workspaceId) onMoveSelectedExposeWindowsToWorkspace;
  final Future<void> Function(String workspaceId) onSetActiveWorkspace;
  final Future<void> Function(String workspaceId) onConfirmCloseTab;
  final VoidCallback onCreateWorkspace;

  Widget _buildWorkspaceTabDragTarget(BuildContext context, Workspace workspace) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != workspace.id,
      onAcceptWithDetails: (details) => onReorderOpenWorkspace(details.data, workspace.id),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty || windowDragTargetWorkspaceId == workspace.id;
        return _WorkspaceTabBoundsReporter(
          workspaceId: workspace.id,
          uiHandles: uiHandles,
          child: Draggable<String>(
            data: workspace.id,
            maxSimultaneousDrags: 1,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: () => onSetDraggingTabWorkspaceId(workspace.id),
            onDragEnd: (_) => onSetDraggingTabWorkspaceId(null),
            onDraggableCanceled: (_, __) => onSetDraggingTabWorkspaceId(null),
            feedback: Material(
              color: Colors.transparent,
              child: AppTab(
                workspace: workspace,
                activeWorkspaceId: activeWorkspaceId,
                isLibraryScreen: isLibraryScreen,
                shouldMoveSelectedWindows: shouldMoveSelectedWindows,
                draggingTabWorkspaceId: draggingTabWorkspaceId,
                isDropTarget: false,
                onMoveSelectedExposeWindowsToWorkspace: onMoveSelectedExposeWindowsToWorkspace,
                onSetActiveWorkspace: onSetActiveWorkspace,
                onConfirmCloseTab: onConfirmCloseTab,
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
                onMoveSelectedExposeWindowsToWorkspace: onMoveSelectedExposeWindowsToWorkspace,
                onSetActiveWorkspace: onSetActiveWorkspace,
                onConfirmCloseTab: onConfirmCloseTab,
              ),
            ),
            child: AppTab(
              workspace: workspace,
              activeWorkspaceId: activeWorkspaceId,
              isLibraryScreen: isLibraryScreen,
              shouldMoveSelectedWindows: shouldMoveSelectedWindows,
              draggingTabWorkspaceId: draggingTabWorkspaceId,
              isDropTarget: isDropTarget,
              onMoveSelectedExposeWindowsToWorkspace: onMoveSelectedExposeWindowsToWorkspace,
              onSetActiveWorkspace: onSetActiveWorkspace,
              onConfirmCloseTab: onConfirmCloseTab,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewChip() {
    return GlassChip(
      selected: isLibraryScreen,
      onTap: onShowWorkspaceOverview,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.dashboard_outlined, size: 15), SizedBox(width: 6), Text('View All')],
      ),
    );
  }

  Widget _buildAddWorkspaceChip() {
    return GlassChip(onTap: onCreateWorkspace, child: const Icon(Icons.add_rounded, size: 16));
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

class _WorkspaceTabBoundsReporter extends StatefulWidget {
  const _WorkspaceTabBoundsReporter({required this.workspaceId, required this.uiHandles, required this.child});

  final String workspaceId;
  final AppUiHandles uiHandles;
  final Widget child;

  @override
  State<_WorkspaceTabBoundsReporter> createState() => _WorkspaceTabBoundsReporterState();
}

class _WorkspaceTabBoundsReporterState extends State<_WorkspaceTabBoundsReporter> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportBounds());
  }

  @override
  void didUpdateWidget(covariant _WorkspaceTabBoundsReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      oldWidget.uiHandles.removeWorkspaceTabBounds(oldWidget.workspaceId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportBounds());
  }

  @override
  void dispose() {
    widget.uiHandles.removeWorkspaceTabBounds(widget.workspaceId);
    super.dispose();
  }

  void _reportBounds() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }

    final topLeft = box.localToGlobal(Offset.zero);
    widget.uiHandles.setWorkspaceTabBounds(widget.workspaceId, topLeft & box.size);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportBounds());
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

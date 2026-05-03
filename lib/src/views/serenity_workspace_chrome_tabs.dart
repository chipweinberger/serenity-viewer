// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellWorkspaceChromeTabs on _SerenityShellState {
  Widget _buildWorkspaceTabBar(BuildContext context) {
    final openWorkspaces = _openWorkspaces;

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        controller: _handles.tabScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildGlassChip(
              context: context,
              selected: _chromeController.isLibraryScreen,
              onTap: _showWorkspaceOverview,
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
                  onAcceptWithDetails: (details) => _reorderOpenWorkspace(details.data, workspace.id),
                  builder: (context, candidateData, rejectedData) {
                    final isDropTarget = candidateData.isNotEmpty;
                    return Draggable<String>(
                      data: workspace.id,
                      maxSimultaneousDrags: 1,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      onDragStarted: () => _chromeController.setDraggingTabWorkspaceId(workspace.id),
                      onDragEnd: (_) => _chromeController.setDraggingTabWorkspaceId(null),
                      onDraggableCanceled: (_, __) => _chromeController.setDraggingTabWorkspaceId(null),
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
              child: _buildGlassChip(
                context: context,
                onTap: _createWorkspace,
                child: const Icon(Icons.add_rounded, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceTabChip(BuildContext context, WorkspaceState workspace, {required bool isDropTarget}) {
    final isSelected = _chromeController.isWorkspaceTabSelected(
      workspaceId: workspace.id,
      activeWorkspaceId: _persistenceState.session!.activeWorkspaceId,
    );
    final shouldMoveSelectedWindows = _chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isDropTarget ? 1.04 : 1,
      child: Opacity(
        opacity: _chromeController.isWorkspaceTabDragging(workspace.id) ? 0.7 : 1,
        child: _buildGlassChip(
          context: context,
          selected: isSelected,
          onTap: () {
            if (shouldMoveSelectedWindows) {
              unawaited(_moveSelectedExposeWindowsToWorkspace(workspace.id));
              return;
            }
            unawaited(_setActiveWorkspace(workspace.id));
          },
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => unawaited(_confirmCloseTab(workspace.id)),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 14, color: isSelected ? Colors.white : SerenityTheme.textMuted),
              ),
            ),
          ),
          child: Text(workspace.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

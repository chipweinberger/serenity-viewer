import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/app_theme.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/library/workspace_card.dart';
import 'package:serenity_viewer/src/media/loading/workspace_load_plan.dart';
import 'package:serenity_viewer/src/shared_widgets/glass_chip.dart';

@immutable
class LibraryScreenActions {
  const LibraryScreenActions({
    required this.onSearchChanged,
    required this.onWorkspaceSortChanged,
    required this.onToggleWorkspaceOpen,
    required this.onRenameWorkspace,
    required this.onDeleteWorkspace,
    required this.onSetActiveWorkspace,
  });

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<WorkspaceSort> onWorkspaceSortChanged;
  final ValueChanged<String> onToggleWorkspaceOpen;
  final Future<void> Function(String workspaceId) onRenameWorkspace;
  final Future<void> Function(String workspaceId) onDeleteWorkspace;
  final Future<void> Function(String workspaceId) onSetActiveWorkspace;
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.allWorkspaces,
    required this.openWorkspaces,
    required this.loadPlan,
    required this.searchController,
    required this.workspaceSort,
    required this.refreshingWorkspaceIds,
    required this.actions,
  });

  final List<Workspace> allWorkspaces;
  final List<Workspace> openWorkspaces;
  final MediaLoadPlan loadPlan;
  final TextEditingController searchController;
  final WorkspaceSort workspaceSort;
  final Set<String> refreshingWorkspaceIds;
  final LibraryScreenActions actions;

  static const double _thumbnailWidth = 224;
  static const double _thumbnailHeight = 192;

  List<Workspace> _visibleOpenWorkspaces() {
    return openWorkspaces.where(_matchesWorkspaceSearch).toList();
  }

  List<Workspace> _sortedKnownWorkspaces() {
    final filtered = allWorkspaces.where(_matchesWorkspaceSearch).toList();

    switch (workspaceSort) {
      case WorkspaceSort.views:
        filtered.sort((a, b) => b.views.compareTo(a.views));
        break;
      case WorkspaceSort.recentlyViewed:
        filtered.sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));
        break;
      case WorkspaceSort.recentlyCreated:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case WorkspaceSort.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return filtered;
  }

  bool _matchesWorkspaceSearch(Workspace workspace) {
    final query = searchController.text.trim().toLowerCase();
    return query.isEmpty || workspace.name.toLowerCase().contains(query);
  }

  Widget _buildWorkspaceCardAction({required String tooltip, required VoidCallback onTap, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceCard(
    Workspace workspace, {
    required List<Widget> hoverActions,
    VoidCallback? onTap,
    bool isDimmed = false,
    String? statusLabel,
  }) {
    return SizedBox(
      width: _thumbnailWidth,
      height: _thumbnailHeight,
      child: WorkspaceCard(
        workspace: workspace,
        mediaCounts: workspaceMediaCounts(workspace),
        unloadedCount: unloadedWorkspaceWindowCount(workspace, loadPlan),
        isRefreshing: refreshingWorkspaceIds.contains(workspace.id),
        isDimmed: isDimmed,
        statusLabel: statusLabel,
        hoverActions: hoverActions,
        onTap: onTap,
      ),
    );
  }

  Widget _buildOpenWorkspaceCard(Workspace workspace) {
    return _buildWorkspaceCard(
      workspace,
      hoverActions: [
        _buildWorkspaceCardAction(
          tooltip: 'Close workspace',
          onTap: () => actions.onToggleWorkspaceOpen(workspace.id),
          icon: Icons.close_rounded,
        ),
        _buildWorkspaceCardAction(
          tooltip: 'Rename workspace',
          onTap: () => unawaited(actions.onRenameWorkspace(workspace.id)),
          icon: Icons.edit_outlined,
        ),
        _buildWorkspaceCardAction(
          tooltip: 'Delete workspace',
          onTap: () => unawaited(actions.onDeleteWorkspace(workspace.id)),
          icon: Icons.delete_outline_rounded,
        ),
      ],
      onTap: () async {
        if (!workspace.isOpen) {
          actions.onToggleWorkspaceOpen(workspace.id);
        }
        await actions.onSetActiveWorkspace(workspace.id);
      },
    );
  }

  Widget _buildKnownWorkspaceCard(Workspace workspace) {
    return _buildWorkspaceCard(
      workspace,
      isDimmed: workspace.isOpen,
      statusLabel: workspace.isOpen ? 'Open' : null,
      hoverActions: [
        _buildWorkspaceCardAction(
          tooltip: 'Rename workspace',
          onTap: () => unawaited(actions.onRenameWorkspace(workspace.id)),
          icon: Icons.edit_outlined,
        ),
        _buildWorkspaceCardAction(
          tooltip: 'Delete workspace',
          onTap: () => unawaited(actions.onDeleteWorkspace(workspace.id)),
          icon: Icons.delete_outline_rounded,
        ),
      ],
      onTap: workspace.isOpen
          ? null
          : () async {
              actions.onToggleWorkspaceOpen(workspace.id);
              await actions.onSetActiveWorkspace(workspace.id);
            },
    );
  }

  Widget _buildWorkspaceSortChips(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        GlassChip(
          selected: workspaceSort == WorkspaceSort.recentlyCreated,
          onTap: () => actions.onWorkspaceSortChanged(WorkspaceSort.recentlyCreated),
          child: const Text('Date created'),
        ),
        GlassChip(
          selected: workspaceSort == WorkspaceSort.name,
          onTap: () => actions.onWorkspaceSortChanged(WorkspaceSort.name),
          child: const Text('Alphabetical'),
        ),
        GlassChip(
          selected: workspaceSort == WorkspaceSort.views,
          onTap: () => actions.onWorkspaceSortChanged(WorkspaceSort.views),
          child: const Text('Most views'),
        ),
        GlassChip(
          selected: workspaceSort == WorkspaceSort.recentlyViewed,
          onTap: () => actions.onWorkspaceSortChanged(WorkspaceSort.recentlyViewed),
          child: const Text('Recently viewed'),
        ),
      ],
    );
  }

  Widget _buildWorkspaceSearchField() {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: searchController,
        onChanged: actions.onSearchChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Search by name',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          filled: true,
          fillColor: AppTheme.panel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildOpenNowSection(BuildContext context, List<Workspace> visibleOpenWorkspaces) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open Now • ${visibleOpenWorkspaces.length}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [for (final workspace in visibleOpenWorkspaces) _buildOpenWorkspaceCard(workspace)],
        ),
      ],
    );
  }

  Widget _buildAllWorkspacesSection(
    BuildContext context, {
    required List<Workspace> knownWorkspaces,
    required int knownWorkspaceCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'All Workspaces • $knownWorkspaceCount',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
            ),
            _buildWorkspaceSearchField(),
          ],
        ),
        const SizedBox(height: 12),
        _buildWorkspaceSortChips(context),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [for (final workspace in knownWorkspaces) _buildKnownWorkspaceCard(workspace)],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleOpenWorkspaces = _visibleOpenWorkspaces();
    final knownWorkspaces = _sortedKnownWorkspaces();
    final knownWorkspaceCount = knownWorkspaces.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5EBD8), Color(0xFFE0D1BA)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 88, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight - 116),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOpenNowSection(context, visibleOpenWorkspaces),
                    const SizedBox(height: 48),
                    _buildAllWorkspacesSection(
                      context,
                      knownWorkspaces: knownWorkspaces,
                      knownWorkspaceCount: knownWorkspaceCount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

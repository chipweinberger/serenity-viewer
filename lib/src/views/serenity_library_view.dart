// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellLibraryView on _SerenityShellState {
  Widget _buildWorkspaceOverview(BuildContext context) {
    final visibleOpenWorkspaces = _openWorkspaces.where(_matchesWorkspaceSearch).toList();
    final knownWorkspaces = _sortedKnownWorkspaces();
    final loadPlan = _buildLoadPlan();
    const thumbnailWidth = 224.0;
    const thumbnailHeight = 192.0;
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
                    Text(
                      'Open Now • ${visibleOpenWorkspaces.length}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: SerenityTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final workspace in visibleOpenWorkspaces)
                          SizedBox(
                            width: thumbnailWidth,
                            height: thumbnailHeight,
                            child: WorkspaceThumbnailCard(
                              workspace: workspace,
                              mediaCounts: _mediaCountsForWorkspace(workspace),
                              unloadedCount: _unloadedCountForWorkspace(workspace, loadPlan),
                              isRefreshing: _thumbnailRefreshInFlight.contains(workspace.id),
                              hoverActions: [
                                _buildWorkspaceCardAction(
                                  tooltip: 'Close workspace',
                                  onTap: () => _toggleWorkspaceOpen(workspace.id),
                                  icon: Icons.close_rounded,
                                ),
                                _buildWorkspaceCardAction(
                                  tooltip: 'Rename workspace',
                                  onTap: () => unawaited(_renameWorkspace(workspace.id)),
                                  icon: Icons.edit_outlined,
                                ),
                                _buildWorkspaceCardAction(
                                  tooltip: 'Delete workspace',
                                  onTap: () => unawaited(_confirmDeleteWorkspace(workspace.id)),
                                  icon: Icons.delete_outline_rounded,
                                ),
                              ],
                              onTap: () {
                                if (!workspace.isOpen) {
                                  _toggleWorkspaceOpen(workspace.id);
                                }
                                unawaited(_setActiveWorkspace(workspace.id));
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'All Workspaces • $knownWorkspaceCount',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: SerenityTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search_rounded),
                              hintText: 'Search by name',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: SerenityTheme.panel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildGlassChip(
                          context: context,
                          selected: _workspaceSort == WorkspaceSort.recentlyCreated,
                          onTap: () => setState(() => _workspaceSort = WorkspaceSort.recentlyCreated),
                          child: const Text('Date created'),
                        ),
                        _buildGlassChip(
                          context: context,
                          selected: _workspaceSort == WorkspaceSort.name,
                          onTap: () => setState(() => _workspaceSort = WorkspaceSort.name),
                          child: const Text('Alphabetical'),
                        ),
                        _buildGlassChip(
                          context: context,
                          selected: _workspaceSort == WorkspaceSort.views,
                          onTap: () => setState(() => _workspaceSort = WorkspaceSort.views),
                          child: const Text('Most views'),
                        ),
                        _buildGlassChip(
                          context: context,
                          selected: _workspaceSort == WorkspaceSort.recentlyViewed,
                          onTap: () => setState(() => _workspaceSort = WorkspaceSort.recentlyViewed),
                          child: const Text('Recently viewed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final workspace in knownWorkspaces)
                          SizedBox(
                            width: thumbnailWidth,
                            height: thumbnailHeight,
                            child: WorkspaceThumbnailCard(
                              workspace: workspace,
                              mediaCounts: _mediaCountsForWorkspace(workspace),
                              unloadedCount: _unloadedCountForWorkspace(workspace, loadPlan),
                              isRefreshing: _thumbnailRefreshInFlight.contains(workspace.id),
                              isDimmed: workspace.isOpen,
                              statusLabel: workspace.isOpen ? 'Open' : null,
                              hoverActions: [
                                _buildWorkspaceCardAction(
                                  tooltip: 'Rename workspace',
                                  onTap: () => unawaited(_renameWorkspace(workspace.id)),
                                  icon: Icons.edit_outlined,
                                ),
                                _buildWorkspaceCardAction(
                                  tooltip: 'Delete workspace',
                                  onTap: () => unawaited(_confirmDeleteWorkspace(workspace.id)),
                                  icon: Icons.delete_outline_rounded,
                                ),
                              ],
                              onTap: workspace.isOpen
                                  ? null
                                  : () {
                                      _toggleWorkspaceOpen(workspace.id);
                                      unawaited(_setActiveWorkspace(workspace.id));
                                    },
                            ),
                          ),
                      ],
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

  bool _matchesWorkspaceSearch(WorkspaceState workspace) {
    final query = _searchController.text.trim().toLowerCase();
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

  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading || _session == null) {
      return _buildLoadingView();
    }

    final activeScreenIndex = switch (_screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: activeScreenIndex,
            children: [_buildWorkspaceScreen(context), _buildWorkspaceOverview(context)],
          ),
        ),
        Positioned(left: 18, right: 18, top: 28, child: _buildWorkspaceTabBar(context)),
        Positioned(top: 10, left: 120, right: 120, child: Center(child: _buildWindowTitleLabel(context))),
      ],
    );
  }
}

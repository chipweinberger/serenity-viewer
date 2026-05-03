// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellWorkspaceChrome on _SerenityShellState {
  static const double _workspaceHudGap = 10;

  Widget _buildTopChromeHitBlock() {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 84,
      child: AbsorbPointer(absorbing: true, child: ColoredBox(color: Colors.transparent)),
    );
  }

  Widget _buildWorkspaceHudAction({required String tooltip, required VoidCallback? onTap, required Widget child}) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.white.withValues(alpha: 0.52),
            child: InkWell(onTap: onTap, child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowTitleLabel(BuildContext context) {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DefaultTextStyle(
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: SerenityTheme.textMuted, fontWeight: FontWeight.w600),
          child: Text(_windowTitle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildWorkspaceTabBar(BuildContext context) {
    final openWorkspaces = _openWorkspaces;

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildGlassChip(
              context: context,
              selected: _screen == SerenityScreen.library,
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
                      onDragStarted: () => setState(() => _draggingTabWorkspaceId = workspace.id),
                      onDragEnd: (_) => setState(() => _draggingTabWorkspaceId = null),
                      onDraggableCanceled: (_, __) => setState(() => _draggingTabWorkspaceId = null),
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
    final isSelected = _screen != SerenityScreen.library && workspace.id == _session!.activeWorkspaceId;
    final shouldMoveSelectedWindows = _screen == SerenityScreen.workspace && _selectedExposeWindowIds.isNotEmpty;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isDropTarget ? 1.04 : 1,
      child: Opacity(
        opacity: _draggingTabWorkspaceId == workspace.id ? 0.7 : 1,
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

  Widget _buildGlassChip({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: selected ? const Color(0xFF1F1E24).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.42),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 38),
              child: Padding(
                padding: EdgeInsets.fromLTRB(11, 8, trailing == null ? 11 : 8, 8),
                child: IconTheme(
                  data: IconThemeData(color: selected ? Colors.white : SerenityTheme.textPrimary),
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: selected ? Colors.white : SerenityTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: child),
                        if (trailing != null) ...[const SizedBox(width: 8), trailing],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceHud(BuildContext context) {
    final mediaCounts = _mediaCountsForWorkspace(_activeWorkspace);
    final imageLabel = '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}';
    final videoLabel = '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}';
    final linkLabel = '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}';
    final isExposeMode = _screen == SerenityScreen.workspace && _workspaceLayoutMode == WorkspaceLayoutMode.expose;
    final showExposeSelectionHud = _screen == SerenityScreen.workspace && _selectedExposeWindowIds.isNotEmpty;
    final selectedCount = _selectedExposeWindowIds.length;
    final modeActions = <Widget>[
      if (!isExposeMode) ...[
        _buildWorkspaceHudAction(
          tooltip: 'Zoom to fit',
          onTap: _fitWorkspaceViewportToContent,
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.fit_screen_rounded, size: 17, color: SerenityTheme.textPrimary),
          ),
        ),
        _buildWorkspaceHudAction(
          tooltip: 'Collate',
          onTap: () => unawaited(_confirmCollateWorkspaceWindows()),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.gps_fixed_rounded, size: 18, color: SerenityTheme.textPrimary),
          ),
        ),
        _buildWorkspaceZoomControl(context),
      ] else
        _buildWorkspaceHudAction(
          tooltip: 'Apply grid to freeform',
          onTap: () => unawaited(_confirmApplyExposeGridToWorkspace()),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.task_alt_rounded, size: 18, color: SerenityTheme.textPrimary),
          ),
        ),
      _buildWorkspaceHudAction(
        tooltip: 'Links',
        onTap: () => unawaited(_openWorkspaceLinksDialog(_activeWorkspace)),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.menu_rounded, size: 18, color: SerenityTheme.textPrimary),
        ),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWorkspaceHudAction(
          tooltip: _workspaceLayoutMode == WorkspaceLayoutMode.expose ? 'Freeform' : 'Expose',
          onTap: _toggleExpose,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              _workspaceLayoutMode == WorkspaceLayoutMode.expose ? Icons.grid_view_rounded : Icons.apps_rounded,
              size: 17,
              color: SerenityTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: _workspaceHudGap),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: SerenityTheme.textMuted, height: 1.1),
                child: Text('$imageLabel, $videoLabel, $linkLabel'),
              ),
            ),
          ),
        ),
        const SizedBox(width: _workspaceHudGap),
        for (var i = 0; i < modeActions.length; i++) ...[
          if (i > 0) const SizedBox(width: _workspaceHudGap),
          modeActions[i],
        ],
        if (showExposeSelectionHud) ...[
          const SizedBox(width: _workspaceHudGap),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(minHeight: 38),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: SerenityTheme.textMuted, height: 1.1),
                        child: Text('$selectedCount selected'),
                      ),
                      const SizedBox(width: 8),
                      DefaultTextStyle(
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: SerenityTheme.textMuted, height: 1.1),
                        child: const Text('·'),
                      ),
                      const SizedBox(width: 8),
                      DefaultTextStyle(
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: SerenityTheme.textMuted, height: 1.1),
                        child: const Text('Click workspace to move'),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _clearExposeSelection,
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close_rounded, size: 14, color: SerenityTheme.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkspaceZoomControl(BuildContext context) {
    final zoomValue = _workspaceZoomSliderValue(_activeWorkspace.viewportZoom);

    return Tooltip(
      message: 'Workspace zoom',
      waitDuration: const Duration(milliseconds: 350),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 170,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(Icons.remove_rounded, size: 14, color: SerenityTheme.textMuted.withValues(alpha: 0.9)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: SerenityTheme.textPrimary,
                      inactiveTrackColor: SerenityTheme.textMuted.withValues(alpha: 0.18),
                      thumbColor: SerenityTheme.textPrimary,
                      overlayColor: SerenityTheme.textPrimary.withValues(alpha: 0.14),
                    ),
                    child: Slider(
                      value: zoomValue,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        _setWorkspaceViewport(
                          workspaceId: _activeWorkspace.id,
                          zoom: _workspaceZoomForSliderValue(value),
                          queueThumbnail: false,
                        );
                      },
                      onChangeEnd: (_) => unawaited(_refreshActiveWorkspaceThumbnailIfNeeded()),
                    ),
                  ),
                ),
                Icon(Icons.add_rounded, size: 14, color: SerenityTheme.textMuted.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _workspaceZoomSliderValue(double zoom) {
    final safeZoom = zoom.clamp(_workspaceMinZoom, _workspaceMaxZoom);
    final minLog = math.log(_workspaceMinZoom);
    final maxLog = math.log(_workspaceMaxZoom);
    final zoomLog = math.log(safeZoom);
    return (zoomLog - minLog) / (maxLog - minLog);
  }

  double _workspaceZoomForSliderValue(double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    final minLog = math.log(_workspaceMinZoom);
    final maxLog = math.log(_workspaceMaxZoom);
    final zoomLog = minLog + ((maxLog - minLog) * clampedValue);
    return math.exp(zoomLog);
  }
}

part of '../app/serenity_shell.dart';

extension _SerenityShellWorkspaceChromeHud on _SerenityShellState {
  Widget _buildWorkspaceHud(BuildContext context) {
    final mediaCounts = workspaceMediaCounts(_activeWorkspace);
    final imageLabel = '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}';
    final videoLabel = '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}';
    final linkLabel = '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}';
    final isExposeMode = _chromeController.isExposeMode;
    final showExposeSelectionHud = _chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap;
    final selectedCount = _windowInteractionState.selectedExposeWindowIds.length;
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
          tooltip: _chromeController.isExposeMode ? 'Freeform' : 'Expose',
          onTap: _toggleExpose,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              _chromeController.isExposeMode ? Icons.grid_view_rounded : Icons.apps_rounded,
              size: 17,
              color: SerenityTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: _SerenityShellWorkspaceChrome._workspaceHudGap),
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
                child: Text('$imageLabel · $videoLabel · $linkLabel'),
              ),
            ),
          ),
        ),
        const SizedBox(width: _SerenityShellWorkspaceChrome._workspaceHudGap),
        for (var i = 0; i < modeActions.length; i++) ...[
          if (i > 0) const SizedBox(width: _SerenityShellWorkspaceChrome._workspaceHudGap),
          modeActions[i],
        ],
        if (showExposeSelectionHud) ...[
          const SizedBox(width: _SerenityShellWorkspaceChrome._workspaceHudGap),
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
    final safeZoom = zoom.clamp(workspaceMinZoom, workspaceMaxZoom);
    final minLog = math.log(workspaceMinZoom);
    final maxLog = math.log(workspaceMaxZoom);
    final zoomLog = math.log(safeZoom);
    return (zoomLog - minLog) / (maxLog - minLog);
  }

  double _workspaceZoomForSliderValue(double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    final minLog = math.log(workspaceMinZoom);
    final maxLog = math.log(workspaceMaxZoom);
    final zoomLog = minLog + ((maxLog - minLog) * clampedValue);
    return math.exp(zoomLog);
  }
}

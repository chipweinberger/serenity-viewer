// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

List<({AssetWindowState window, Rect rect})> _computeExposeLayoutRects({
  required List<AssetWindowState> windows,
  required Size viewportSize,
}) {
  const horizontalPadding = 28.0;
  const topPadding = 86.0;
  const bottomPadding = 92.0;
  const spacing = 22.0;
  const maxCardHeight = 220.0;
  const minCardHeight = 56.0;

  if (windows.isEmpty || viewportSize.width <= 0 || viewportSize.height <= 0) {
    return const [];
  }

  final availableWidth = math.max(0.0, viewportSize.width - (horizontalPadding * 2));
  final availableHeight = math.max(0.0, viewportSize.height - topPadding - bottomPadding);
  final aspectRatios = windows
      .map((window) => math.max(0.2, window.size.width / math.max(1.0, window.size.height)))
      .toList();

  double totalHeightForRowHeight(double rowHeight) {
    var rows = 1;
    var rowWidth = 0.0;
    for (final aspectRatio in aspectRatios) {
      final itemWidth = rowHeight * aspectRatio;
      if (itemWidth > availableWidth) {
        return double.infinity;
      }

      final nextWidth = rowWidth == 0 ? itemWidth : rowWidth + spacing + itemWidth;
      if (nextWidth > availableWidth + 0.001) {
        rows += 1;
        rowWidth = itemWidth;
      } else {
        rowWidth = nextWidth;
      }
    }
    return (rows * rowHeight) + ((rows - 1) * spacing);
  }

  var low = minCardHeight;
  var high = math.min(maxCardHeight, availableHeight);
  var bestCardHeight = low;
  for (var i = 0; i < 24; i++) {
    final candidate = (low + high) / 2;
    final totalHeight = totalHeightForRowHeight(candidate);
    if (totalHeight <= availableHeight + 0.001) {
      bestCardHeight = candidate;
      low = candidate;
    } else {
      high = candidate;
    }
  }

  final rows = <List<({AssetWindowState window, double width})>>[];
  var currentRow = <({AssetWindowState window, double width})>[];
  var currentRowWidth = 0.0;
  for (final window in windows) {
    final itemWidth = bestCardHeight * math.max(0.2, window.size.width / math.max(1.0, window.size.height));
    final nextWidth = currentRow.isEmpty ? itemWidth : currentRowWidth + spacing + itemWidth;
    if (currentRow.isNotEmpty && nextWidth > availableWidth + 0.001) {
      rows.add(currentRow);
      currentRow = [];
      currentRowWidth = 0.0;
    }
    currentRow.add((window: window, width: itemWidth));
    currentRowWidth = currentRow.length == 1 ? itemWidth : currentRowWidth + spacing + itemWidth;
  }
  if (currentRow.isNotEmpty) {
    rows.add(currentRow);
  }

  final totalGridHeight = (rows.length * bestCardHeight) + (math.max(0, rows.length - 1) * spacing);
  var top = topPadding + math.max(0.0, (availableHeight - totalGridHeight) / 2);
  final layouts = <({AssetWindowState window, Rect rect})>[];

  for (final row in rows) {
    final rowWidth =
        row.fold<double>(0.0, (value, entry) => value + entry.width) + (math.max(0, row.length - 1) * spacing);
    var left = horizontalPadding + math.max(0.0, (availableWidth - rowWidth) / 2);
    for (final entry in row) {
      layouts.add((window: entry.window, rect: Rect.fromLTWH(left, top, entry.width, bestCardHeight)));
      left += entry.width + spacing;
    }
    top += bestCardHeight + spacing;
  }

  return layouts;
}

extension _SerenityShellWorkspaceView on _SerenityShellState {
  Widget _buildEmptyWorkspaceCanvasState(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: SerenityTheme.textMuted.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  'Empty workspace',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: SerenityTheme.textPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag and drop media here',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: SerenityTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformWorkspaceViewport(
    BuildContext context,
    WorkspaceState workspace,
    List<AssetWindowState> windows,
    SerenityLoadPlan loadPlan,
    String? focusedWindowId,
  ) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          _workspaceViewportSize = viewportSize;

          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: (event) => _handleOptionGestureHover(event, workspace),
            onPointerPanZoomStart: (event) => _handleWorkspacePanZoomStart(event, workspace),
            onPointerPanZoomUpdate: (event) => _handleWorkspacePanZoomUpdate(event, workspace, viewportSize),
            onPointerPanZoomEnd: (_) => _handleWorkspacePanZoomEnd(),
            child: Stack(
              children: [
                for (final window in windows)
                  Builder(
                    builder: (context) {
                      final screenOffset = _workspaceScreenOffsetForWindow(workspace, window, viewportSize);
                      final isLoaded = loadPlan.loadedAssetIds.contains(window.asset.id);
                      final sharedVideoControllerEntry = _sharedVideoControllerForWindow(window, isLoaded: isLoaded);
                      return Positioned(
                        key: ValueKey(window.asset.id),
                        left: screenOffset.dx,
                        top: screenOffset.dy,
                        child: Transform.scale(
                          scale: workspace.viewportZoom,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: window.size.width,
                            height: window.size.height,
                            child: SerenityWindowFrame(
                              window: window,
                              isLoaded: isLoaded,
                              sharedVideoController: sharedVideoControllerEntry?.controller,
                              sharedVideoInitialization: sharedVideoControllerEntry?.initialization,
                              isFocused: window.asset.id == focusedWindowId,
                              isSelected: _selectedExposeWindowIds.contains(window.asset.id),
                              isEditing: false,
                              onTap: () => _focusWindow(window.asset.id),
                              onToggleSelected: () => _toggleExposeWindowSelected(window.asset.id),
                              onPanUpdate: (delta) => _moveWindow(window.asset.id, delta / workspace.viewportZoom),
                              onTrackpadWindowScale: (scaleDelta, localFocalPoint) => _transformWindowFromTrackpad(
                                window.asset.id,
                                scaleDelta,
                                localFocalPoint / workspace.viewportZoom,
                              ),
                              onResizeUpdate: (handle, delta) =>
                                  _resizeWindow(window.asset.id, handle, delta / workspace.viewportZoom),
                              onZoomChanged: (update) => _setWindowZoom(window.asset.id, update),
                              onIntrinsicSizeResolved: (size) => _setWindowIntrinsicSize(window.asset.id, size),
                              isVideoPaused: _isVideoWindowPaused(window.asset.id),
                              onVideoPositionChanged: (positionMs) => _setVideoPosition(window.asset.id, positionMs),
                              onCycleVideoPlaybackSpeed: () => _cycleVideoPlaybackSpeed(window.asset.id),
                              onTogglePlayback: () => _toggleVideoPlayback(window.asset.id),
                              onFitToContent: () => _fitWindowToContent(window.asset.id),
                              onShowInFinder: window.asset.filePath == null
                                  ? null
                                  : () => unawaited(_revealAssetInFinder(window.asset)),
                              onRestorePreviousZOrder: _previousWindowZOrders.containsKey(window.asset.id)
                                  ? () => _restorePreviousWindowZOrder(window.asset.id)
                                  : null,
                              onClose: () => _removeWindow(_session!.activeWorkspaceId, window.asset.id),
                              isOptionGestureTarget: _optionGestureWindowId == window.asset.id,
                              onOptionGestureWindowRequested: () => _setOptionGestureWindowId(window.asset.id),
                              onOptionGestureReleased: () => _setOptionGestureWindowId(null),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkspaceCanvas(BuildContext context, WorkspaceState workspace) {
    final isActiveWorkspace = workspace.id == _session!.activeWorkspaceId;
    final isExposeMode =
        isActiveWorkspace && _screen == SerenityScreen.workspace && _workspaceLayoutMode == WorkspaceLayoutMode.expose;
    final windows = isExposeMode
        ? ([...workspace.windows]..sort((a, b) => a.asset.filename.compareTo(b.asset.filename)))
        : ([...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex)));
    final focusedWindowId = windows.isEmpty || isExposeMode ? null : windows.last.asset.id;
    final loadPlan = _buildLoadPlan();
    _syncSharedVideoControllers(loadPlan);

    return DropTarget(
      onDragEntered: (_) {
        setState(() {
          _isDropTargetActive = true;
        });
      },
      onDragExited: (_) {
        setState(() {
          _isDropTargetActive = false;
        });
      },
      onDragDone: (details) async {
        setState(() {
          _isDropTargetActive = false;
        });
        await _importFiles(details.files);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SerenityTheme.background, SerenityTheme.backgroundShade],
                ),
              ),
            ),
          ),
          if (isExposeMode)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportSize = constraints.biggest;
                  _workspaceViewportSize = viewportSize;

                  if (windows.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final exposeLayouts = _computeExposeLayoutRects(windows: windows, viewportSize: viewportSize);

                  return Stack(
                    children: [
                      for (final layout in exposeLayouts)
                        Positioned.fromRect(
                          rect: layout.rect,
                          child: Builder(
                            builder: (context) {
                              final window = layout.window;
                              final isLoaded = loadPlan.loadedAssetIds.contains(window.asset.id);
                              final sharedVideoControllerEntry = _sharedVideoControllerForWindow(
                                window,
                                isLoaded: isLoaded,
                              );
                              return ExposeWindowCard(
                                window: window,
                                isLoaded: isLoaded,
                                sharedVideoController: sharedVideoControllerEntry?.controller,
                                sharedVideoInitialization: sharedVideoControllerEntry?.initialization,
                                isVideoPaused: _isVideoWindowPaused(window.asset.id),
                                isSelected: _selectedExposeWindowIds.contains(window.asset.id),
                                editMode: _editMode,
                                onOpen: () {
                                  _focusWindow(window.asset.id);
                                  _toggleExpose();
                                },
                                onToggleSelected: () => _toggleExposeWindowSelected(window.asset.id),
                                onShowInFinder: window.asset.filePath == null
                                    ? null
                                    : () => unawaited(_revealAssetInFinder(window.asset)),
                                onRemove: () => _removeWindow(_session!.activeWorkspaceId, window.asset.id),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            )
          else
            _buildFreeformWorkspaceViewport(context, workspace, windows, loadPlan, focusedWindowId),
          if (!isExposeMode && windows.isEmpty) Positioned.fill(child: _buildEmptyWorkspaceCanvasState(context)),
          if (_isDropTargetActive)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.42),
                    child: const Center(
                      child: Text(
                        'Drop media here',
                        style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(left: 18, bottom: 18, child: _buildWorkspaceHud(context)),
        ],
      ),
    );
  }

  Widget _buildWorkspaceScreen(BuildContext context) {
    final openWorkspaces = _openWorkspaces;
    if (openWorkspaces.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeWorkspaceId = _session!.activeWorkspaceId;
    final activeWorkspaceIndex = openWorkspaces.indexWhere((workspace) => workspace.id == activeWorkspaceId);
    final safeActiveIndex = activeWorkspaceIndex < 0 ? 0 : activeWorkspaceIndex;

    return IndexedStack(
      index: safeActiveIndex,
      children: [
        for (final workspace in openWorkspaces)
          KeyedSubtree(key: ValueKey(workspace.id), child: _buildWorkspaceCanvas(context, workspace)),
      ],
    );
  }
}

// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellWorkspaceView on _SerenityShellState {
  SerenitySessionState get _session => _persistenceState.session!;

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

  bool _isExposeModeForWorkspace(WorkspaceState workspace) {
    return workspace.id == _session.activeWorkspaceId &&
        _uiState.screen == SerenityScreen.workspace &&
        _uiState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
  }

  List<AssetWindowState> _sortedWorkspaceWindows(WorkspaceState workspace, {required bool isExposeMode}) {
    final windows = [...workspace.windows];
    if (isExposeMode) {
      windows.sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
    } else {
      windows.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    }
    return windows;
  }

  String? _focusedWindowIdForCanvas(List<AssetWindowState> windows, {required bool isExposeMode}) {
    if (windows.isEmpty || isExposeMode) {
      return null;
    }
    return windows.last.asset.id;
  }

  SerenityLoadPlan _buildCanvasLoadPlan() {
    final loadPlan = buildWorkspaceLoadPlan(session: _session, activeWorkspace: _activeWorkspaceOrNull);
    _syncSharedVideoControllers(loadPlan);
    return loadPlan;
  }

  void _handleWorkspaceDropEntered(DropEventDetails details) {
    setState(() {
      _uiState.isDropTargetActive = true;
    });
  }

  void _handleWorkspaceDropExited(DropEventDetails details) {
    setState(() {
      _uiState.isDropTargetActive = false;
    });
  }

  Future<void> _handleWorkspaceDropDone(DropDoneDetails details) async {
    setState(() {
      _uiState.isDropTargetActive = false;
    });
    await _importFiles(details.files);
  }

  void _trackViewportSize(Size viewportSize) {
    _workspaceViewportState.viewportSize = viewportSize;
  }

  bool _isWindowLoaded(SerenityLoadPlan loadPlan, AssetWindowState window) {
    return loadPlan.loadedAssetIds.contains(window.asset.id);
  }

  _SharedVideoControllerEntry? _sharedVideoEntryForWindow(AssetWindowState window, SerenityLoadPlan loadPlan) {
    return _sharedVideoControllerForWindow(window, isLoaded: _isWindowLoaded(loadPlan, window));
  }

  VoidCallback? _showInFinderCallbackForWindow(AssetWindowState window) {
    return window.asset.filePath == null ? null : () => unawaited(_revealAssetInFinder(window.asset));
  }

  VoidCallback? _restorePreviousZOrderCallbackForWindow(AssetWindowState window) {
    return _windowInteractionState.previousWindowZOrders.containsKey(window.asset.id)
        ? () => _restorePreviousWindowZOrder(window.asset.id)
        : null;
  }

  void _handleFreeformWindowTap(AssetWindowState window) {
    if (_windowInteractionState.pinnedHoverWindowId == window.asset.id) {
      _clearPinnedHoverWindow();
      return;
    }
    _clearPinnedHoverWindow();
    _focusWindow(window.asset.id);
  }

  Widget _buildWorkspaceCanvasBackground() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SerenityTheme.background, SerenityTheme.backgroundShade],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformWindow(
    WorkspaceState workspace,
    AssetWindowState window,
    SerenityLoadPlan loadPlan,
    Size viewportSize,
    String? focusedWindowId,
  ) {
    final screenOffset = workspaceScreenOffsetForWindow(workspace, window, viewportSize);
    final isLoaded = _isWindowLoaded(loadPlan, window);
    final sharedVideoControllerEntry = _sharedVideoEntryForWindow(window, loadPlan);

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
            isSelected: _windowInteractionState.selectedExposeWindowIds.contains(window.asset.id),
            isEditing: false,
            isPinnedHover: _windowInteractionState.pinnedHoverWindowId == window.asset.id,
            workspaceZoom: workspace.viewportZoom,
            onTap: () => _handleFreeformWindowTap(window),
            onPinnedHoverRequested: () => _setPinnedHoverWindow(window.asset.id),
            onPinnedHoverDismissed: _clearPinnedHoverWindow,
            onToggleSelected: () => _toggleExposeWindowSelected(window.asset.id),
            flashNonce: window.asset.id == _windowInteractionState.flashedWindowId
                ? _windowInteractionState.windowFlashNonce
                : 0,
            onPanUpdate: (delta) => _moveWindow(window.asset.id, delta / workspace.viewportZoom),
            onTrackpadWindowScale: (scaleDelta, localFocalPoint) =>
                _transformWindowFromTrackpad(window.asset.id, scaleDelta, localFocalPoint / workspace.viewportZoom),
            onResizeUpdate: (handle, delta) => _resizeWindow(window.asset.id, handle, delta / workspace.viewportZoom),
            onZoomChanged: (update) => _setWindowZoom(window.asset.id, update),
            onIntrinsicSizeResolved: (size) => _setWindowIntrinsicSize(window.asset.id, size),
            isVideoPaused: _isVideoWindowPaused(window.asset.id),
            onVideoPositionChanged: (positionMs) => _setVideoPosition(window.asset.id, positionMs),
            onCycleVideoPlaybackSpeed: () => _cycleVideoPlaybackSpeed(window.asset.id),
            onTogglePlayback: () => _toggleVideoPlayback(window.asset.id),
            onFitToContent: () => _fitWindowToContent(window.asset.id),
            onShowInFinder: _showInFinderCallbackForWindow(window),
            onRestorePreviousZOrder: _restorePreviousZOrderCallbackForWindow(window),
            onClose: () => _removeWindow(_session.activeWorkspaceId, window.asset.id),
            isOptionGestureTarget: _windowInteractionState.optionGestureWindowId == window.asset.id,
            onOptionGestureWindowRequested: () => _setOptionGestureWindowId(window.asset.id),
            onOptionGestureReleased: () => _setOptionGestureWindowId(null),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformWorkspaceViewport(
    WorkspaceState workspace,
    List<AssetWindowState> windows,
    SerenityLoadPlan loadPlan,
    String? focusedWindowId,
  ) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          _trackViewportSize(viewportSize);

          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: (event) => _handleOptionGestureHover(event, workspace),
            onPointerPanZoomStart: (event) => _handleWorkspacePanZoomStart(event, workspace),
            onPointerPanZoomUpdate: (event) => _handleWorkspacePanZoomUpdate(event, workspace, viewportSize),
            onPointerPanZoomEnd: (_) => _handleWorkspacePanZoomEnd(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _clearPinnedHoverWindow,
                    child: const SizedBox.expand(),
                  ),
                ),
                for (final window in windows)
                  _buildFreeformWindow(workspace, window, loadPlan, viewportSize, focusedWindowId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExposeWindowCard(SerenityWindowLayout layout, SerenityLoadPlan loadPlan) {
    final window = layout.window;
    final isLoaded = _isWindowLoaded(loadPlan, window);
    final sharedVideoControllerEntry = _sharedVideoEntryForWindow(window, loadPlan);

    return Positioned.fromRect(
      rect: layout.rect,
      child: ExposeWindowCard(
        window: window,
        isLoaded: isLoaded,
        sharedVideoController: sharedVideoControllerEntry?.controller,
        sharedVideoInitialization: sharedVideoControllerEntry?.initialization,
        isVideoPaused: _isVideoWindowPaused(window.asset.id),
        isSelected: _windowInteractionState.selectedExposeWindowIds.contains(window.asset.id),
        editMode: _uiState.editMode,
        onOpen: () {
          _focusWindow(window.asset.id);
          _toggleExpose();
          _flashWindow(window.asset.id);
        },
        onToggleSelected: () => _toggleExposeWindowSelected(window.asset.id),
        onShowInFinder: _showInFinderCallbackForWindow(window),
        onRemove: () => _removeWindow(_session.activeWorkspaceId, window.asset.id),
      ),
    );
  }

  Widget _buildExposeWorkspaceViewport(List<AssetWindowState> windows, SerenityLoadPlan loadPlan) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          _trackViewportSize(viewportSize);

          if (windows.isEmpty) {
            return const SizedBox.shrink();
          }

          final exposeLayouts = computeExposeLayoutRects(windows: windows, viewportSize: viewportSize);
          return Stack(children: [for (final layout in exposeLayouts) _buildExposeWindowCard(layout, loadPlan)]);
        },
      ),
    );
  }

  Widget _buildWorkspaceDropOverlay() {
    return Positioned.fill(
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
    );
  }

  Widget _buildWorkspaceCanvasLayers(
    BuildContext context,
    WorkspaceState workspace, {
    required bool isExposeMode,
    required List<AssetWindowState> windows,
    required SerenityLoadPlan loadPlan,
    required String? focusedWindowId,
  }) {
    return Stack(
      children: [
        _buildWorkspaceCanvasBackground(),
        if (isExposeMode)
          _buildExposeWorkspaceViewport(windows, loadPlan)
        else
          _buildFreeformWorkspaceViewport(workspace, windows, loadPlan, focusedWindowId),
        if (!isExposeMode && windows.isEmpty) Positioned.fill(child: _buildEmptyWorkspaceCanvasState(context)),
        if (_uiState.isDropTargetActive) _buildWorkspaceDropOverlay(),
        Positioned(left: 18, bottom: 18, child: _buildWorkspaceHud(context)),
      ],
    );
  }

  Widget _buildWorkspaceCanvas(BuildContext context, WorkspaceState workspace) {
    final isExposeMode = _isExposeModeForWorkspace(workspace);
    final windows = _sortedWorkspaceWindows(workspace, isExposeMode: isExposeMode);
    final focusedWindowId = _focusedWindowIdForCanvas(windows, isExposeMode: isExposeMode);
    final loadPlan = _buildCanvasLoadPlan();

    return DropTarget(
      onDragEntered: _handleWorkspaceDropEntered,
      onDragExited: _handleWorkspaceDropExited,
      onDragDone: _handleWorkspaceDropDone,
      child: _buildWorkspaceCanvasLayers(
        context,
        workspace,
        isExposeMode: isExposeMode,
        windows: windows,
        loadPlan: loadPlan,
        focusedWindowId: focusedWindowId,
      ),
    );
  }

  Widget _buildWorkspaceScreen(BuildContext context) {
    final openWorkspaces = _openWorkspaces;
    if (openWorkspaces.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeWorkspaceId = _session.activeWorkspaceId;
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

// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/app_shell.dart';

extension _AppShellContent on _AppShellState {
  Widget _buildShellContent(BuildContext context) {
    if (_persistenceState.isLoading || _persistenceState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final environment = _persistenceState.environment!;
    final workspaceLoadPlan = buildWorkspaceLoadPlan(environment: environment, activeWorkspace: _activeWorkspaceOrNull);
    _mediaBridge.syncSharedVideoControllers(loadPlan: workspaceLoadPlan, environment: environment);
    final activeWorkspace = _activeWorkspace;
    final mediaCounts = workspaceMediaCounts(activeWorkspace);
    final workspaceChromeViewModel = WorkspaceChromeViewModel(
      imageLabel: '${mediaCounts.images} image${mediaCounts.images == 1 ? '' : 's'}',
      videoLabel: '${mediaCounts.videos} video${mediaCounts.videos == 1 ? '' : 's'}',
      linkLabel: '${mediaCounts.links} link${mediaCounts.links == 1 ? '' : 's'}',
      isExposeMode: _chromeController.isExposeMode,
      showExposeSelectionHud: _chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
      selectedCount: _windowInteractionState.selectedExposeWindowIds.length,
      workspaceId: activeWorkspace.id,
      workspaceZoom: activeWorkspace.viewportZoom,
    );
    final activeScreenIndex = switch (_uiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: activeScreenIndex,
            children: [
              WorkspaceScreen(
                environment: environment,
                openWorkspaces: _openWorkspaces,
                chromeState: _uiState,
                windowInteractionState: _windowInteractionState,
                loadPlan: workspaceLoadPlan,
                sharedVideoLookup: _mediaBridge.sharedVideoForWindow,
                actions: WorkspaceScreenActions(
                  setDropTargetActive: (isActive) => setState(() => _uiState.isDropTargetActive = isActive),
                  importFiles: _importFiles,
                  trackViewportSize: (viewportSize) => _workspaceViewportState.viewportSize = viewportSize,
                  handleOptionGestureHover: _handleOptionGestureHover,
                  handleWorkspacePanZoomStart: _handleWorkspacePanZoomStart,
                  handleWorkspacePanZoomUpdate: _handleWorkspacePanZoomUpdate,
                  handleWorkspacePanZoomEnd: _handleWorkspacePanZoomEnd,
                  focusWindow: _focusWindow,
                  restorePreviousWindowZOrder: _restorePreviousWindowZOrder,
                  moveWindow: _moveWindow,
                  resizeWindow: _resizeWindow,
                  transformWindowFromTrackpad: _transformWindowFromTrackpad,
                  fitWindowToContent: _fitWindowToContent,
                  setWindowZoom: _setWindowZoom,
                  setVideoPosition: _setVideoPosition,
                  cycleVideoPlaybackSpeed: _cycleVideoPlaybackSpeed,
                  setWindowIntrinsicSize: _setWindowIntrinsicSize,
                  isVideoWindowPaused: _isVideoWindowPaused,
                  toggleVideoPlayback: _toggleVideoPlayback,
                  toggleExpose: _toggleExpose,
                  setPinnedHoverWindow: _setPinnedHoverWindow,
                  clearPinnedHoverWindow: _clearPinnedHoverWindow,
                  flashWindow: _flashWindow,
                  toggleExposeWindowSelected: _toggleExposeWindowSelected,
                  removeWindow: _removeWindow,
                  setOptionGestureWindowId: _setOptionGestureWindowId,
                  revealAssetInFinder: _mediaBridge.revealAssetInFinder,
                ),
                workspaceHud: WorkspaceHud(
                  viewModel: workspaceChromeViewModel,
                  actions: WorkspaceHudActions(
                    onToggleExpose: _toggleExpose,
                    onFitWorkspaceViewportToContent: _fitWorkspaceViewportToContent,
                    onConfirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
                    onConfirmApplyExposeGridToWorkspace: _confirmApplyExposeGridToWorkspace,
                    onOpenWorkspaceLinks: () => showSerenityWorkspaceLinksDialog(
                      context: context,
                      initialWorkspace: activeWorkspace,
                      controller: _workspaceLinksController,
                    ),
                    onClearExposeSelection: _clearExposeSelection,
                    onSetWorkspaceZoom: (workspaceId, zoom) =>
                        _setWorkspaceViewport(workspaceId: workspaceId, zoom: zoom, queueThumbnail: false),
                    onRefreshActiveWorkspaceThumbnail: _refreshActiveWorkspaceThumbnailIfNeeded,
                  ),
                ),
              ),
              LibraryScreen(
                allWorkspaces: _workspaces,
                openWorkspaces: _openWorkspaces,
                loadPlan: workspaceLoadPlan,
                searchController: _handles.searchController,
                workspaceSort: _uiState.workspaceSort,
                refreshingWorkspaceIds: _thumbnailRefreshState.refreshInFlight,
                actions: LibraryScreenActions(
                  onSearchChanged: (_) => setState(() {}),
                  onWorkspaceSortChanged: _chromeController.setWorkspaceSort,
                  onToggleWorkspaceOpen: _toggleWorkspaceOpen,
                  onRenameWorkspace: _renameWorkspace,
                  onDeleteWorkspace: _confirmDeleteWorkspace,
                  onSetActiveWorkspace: _setActiveWorkspace,
                ),
              ),
            ],
          ),
        ),
        WorkspaceChromeOverlay(
          windowTitle: _windowTitle,
          openWorkspaces: _openWorkspaces,
          activeWorkspaceId: environment.activeWorkspaceId,
          isLibraryScreen: _chromeController.isLibraryScreen,
          shouldMoveSelectedWindows: _chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
          draggingTabWorkspaceId: _uiState.draggingTabWorkspaceId,
          tabScrollController: _handles.tabScrollController,
          actions: WorkspaceChromeOverlayActions(
            onShowWorkspaceOverview: () => unawaited(_showWorkspaceOverview()),
            onSetDraggingTabWorkspaceId: _chromeController.setDraggingTabWorkspaceId,
            onReorderOpenWorkspace: _reorderOpenWorkspace,
            onMoveSelectedExposeWindowsToWorkspace: _moveSelectedExposeWindowsToWorkspace,
            onSetActiveWorkspace: _setActiveWorkspace,
            onConfirmCloseTab: _confirmCloseTab,
            onCreateWorkspace: _createWorkspace,
          ),
        ),
      ],
    );
  }
}

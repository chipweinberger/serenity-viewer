// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/serenity_shell.dart';

extension _SerenityShellLibraryView on _SerenityShellState {
  Widget _buildBody(BuildContext context) {
    if (_persistenceState.isLoading || _persistenceState.session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final session = _persistenceState.session!;
    final workspaceLoadPlan = buildWorkspaceLoadPlan(session: session, activeWorkspace: _activeWorkspaceOrNull);
    _mediaBridge.syncSharedVideoControllers(loadPlan: workspaceLoadPlan, session: session);
    final activeWorkspace = _activeWorkspace;
    final mediaCounts = workspaceMediaCounts(activeWorkspace);
    final workspaceChromeViewModel = SerenityWorkspaceChromeViewModel(
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
              SerenityWorkspaceScreen(
                session: session,
                openWorkspaces: _openWorkspaces,
                chromeState: _uiState,
                windowInteractionState: _windowInteractionState,
                loadPlan: workspaceLoadPlan,
                sharedVideoLookup: _mediaBridge.sharedVideoForWindow,
                actions: SerenityWorkspaceScreenActions(
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
                workspaceHud: SerenityWorkspaceHud(
                  viewModel: workspaceChromeViewModel,
                  actions: SerenityWorkspaceHudActions(
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
              SerenityLibraryScreen(
                allWorkspaces: _workspaces,
                openWorkspaces: _openWorkspaces,
                loadPlan: workspaceLoadPlan,
                searchController: _handles.searchController,
                workspaceSort: _uiState.workspaceSort,
                refreshingWorkspaceIds: _thumbnailRefreshState.refreshInFlight,
                actions: SerenityLibraryScreenActions(
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
        SerenityWorkspaceChromeOverlay(
          windowTitle: _windowTitle,
          openWorkspaces: _openWorkspaces,
          activeWorkspaceId: session.activeWorkspaceId,
          isLibraryScreen: _chromeController.isLibraryScreen,
          shouldMoveSelectedWindows: _chromeController.shouldMoveSelectedWindowsToWorkspaceOnTap,
          draggingTabWorkspaceId: _uiState.draggingTabWorkspaceId,
          tabScrollController: _handles.tabScrollController,
          actions: SerenityWorkspaceChromeOverlayActions(
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

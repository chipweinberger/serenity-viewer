import 'dart:async';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/media/playback/media_bridge.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_projection.dart';
import 'package:serenity_viewer/src/workspace/windows/workspace_window_state.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/environments/session/session_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_frame_view_model.dart';
import 'package:serenity_viewer/src/workspace/canvas/workspace_canvas_view_model.dart';
import 'package:serenity_viewer/src/workspace/windows/window_zoom_update.dart';
import 'package:serenity_viewer/src/media/assets/workspace_asset.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/windows/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/expose/expose_window_card.dart';
import 'package:serenity_viewer/src/workspace/windows/window_frame.dart';
import 'package:serenity_viewer/src/workspace/windows/window_resize_helpers.dart';
import 'package:serenity_viewer/src/workspace/expose/expose_layouts.dart';

typedef SerenitySharedVideoLookup =
    SerenitySharedVideoState? Function(AssetWindowState window, {required bool isLoaded});

@immutable
class SerenityWorkspaceScreenActions {
  const SerenityWorkspaceScreenActions({
    required this.setDropTargetActive,
    required this.importFiles,
    required this.trackViewportSize,
    required this.handleOptionGestureHover,
    required this.handleWorkspacePanZoomStart,
    required this.handleWorkspacePanZoomUpdate,
    required this.handleWorkspacePanZoomEnd,
    required this.focusWindow,
    required this.restorePreviousWindowZOrder,
    required this.moveWindow,
    required this.resizeWindow,
    required this.transformWindowFromTrackpad,
    required this.fitWindowToContent,
    required this.setWindowZoom,
    required this.setVideoPosition,
    required this.cycleVideoPlaybackSpeed,
    required this.setWindowIntrinsicSize,
    required this.isVideoWindowPaused,
    required this.toggleVideoPlayback,
    required this.toggleExpose,
    required this.setPinnedHoverWindow,
    required this.clearPinnedHoverWindow,
    required this.flashWindow,
    required this.toggleExposeWindowSelected,
    required this.removeWindow,
    required this.setOptionGestureWindowId,
    required this.revealAssetInFinder,
  });

  final ValueChanged<bool> setDropTargetActive;
  final Future<void> Function(List<XFile> files) importFiles;
  final ValueChanged<Size> trackViewportSize;
  final void Function(PointerHoverEvent event, WorkspaceState workspace) handleOptionGestureHover;
  final void Function(PointerPanZoomStartEvent event, WorkspaceState workspace) handleWorkspacePanZoomStart;
  final void Function(PointerPanZoomUpdateEvent event, WorkspaceState workspace, Size viewportSize)
  handleWorkspacePanZoomUpdate;
  final VoidCallback handleWorkspacePanZoomEnd;
  final ValueChanged<String> focusWindow;
  final ValueChanged<String> restorePreviousWindowZOrder;
  final void Function(String windowId, Offset delta) moveWindow;
  final void Function(String windowId, WindowResizeHandle handle, Offset delta) resizeWindow;
  final void Function(String windowId, double scaleDelta, Offset localFocalPoint) transformWindowFromTrackpad;
  final ValueChanged<String> fitWindowToContent;
  final void Function(String windowId, WindowZoomUpdate update) setWindowZoom;
  final void Function(String windowId, int positionMs) setVideoPosition;
  final ValueChanged<String> cycleVideoPlaybackSpeed;
  final void Function(String windowId, Size intrinsicSize) setWindowIntrinsicSize;
  final bool Function(String windowId) isVideoWindowPaused;
  final ValueChanged<String> toggleVideoPlayback;
  final VoidCallback toggleExpose;
  final ValueChanged<String> setPinnedHoverWindow;
  final VoidCallback clearPinnedHoverWindow;
  final ValueChanged<String> flashWindow;
  final ValueChanged<String> toggleExposeWindowSelected;
  final void Function(String workspaceId, String windowId) removeWindow;
  final ValueChanged<String?> setOptionGestureWindowId;
  final Future<void> Function(WorkspaceAsset asset) revealAssetInFinder;
}

class SerenityWorkspaceScreen extends StatelessWidget {
  const SerenityWorkspaceScreen({
    super.key,
    required this.session,
    required this.openWorkspaces,
    required this.chromeState,
    required this.windowInteractionState,
    required this.loadPlan,
    required this.sharedVideoLookup,
    required this.actions,
    required this.workspaceHud,
  });

  final SerenitySessionState session;
  final List<WorkspaceState> openWorkspaces;
  final SerenityChromeState chromeState;
  final SerenityWindowInteractionState windowInteractionState;
  final SerenityLoadPlan loadPlan;
  final SerenitySharedVideoLookup sharedVideoLookup;
  final SerenityWorkspaceScreenActions actions;
  final Widget workspaceHud;

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
    return workspace.id == session.activeWorkspaceId &&
        chromeState.screen == SerenityScreen.workspace &&
        chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
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

  SerenityWorkspaceCanvasViewModel _buildWorkspaceCanvasViewModel(WorkspaceState workspace) {
    final isExposeMode = _isExposeModeForWorkspace(workspace);
    final windows = _sortedWorkspaceWindows(workspace, isExposeMode: isExposeMode);
    return SerenityWorkspaceCanvasViewModel(
      workspace: workspace,
      isExposeMode: isExposeMode,
      windows: windows,
      focusedWindowId: _focusedWindowIdForCanvas(windows, isExposeMode: isExposeMode),
      loadPlan: loadPlan,
      isDropTargetActive: chromeState.isDropTargetActive,
    );
  }

  bool _isWindowLoaded(SerenityLoadPlan loadPlan, AssetWindowState window) {
    return loadPlan.loadedAssetIds.contains(window.asset.id);
  }

  VoidCallback? _showInFinderCallbackForWindow(AssetWindowState window) {
    return window.asset.filePath == null ? null : () => unawaited(actions.revealAssetInFinder(window.asset));
  }

  VoidCallback? _restorePreviousZOrderCallbackForWindow(AssetWindowState window) {
    return windowInteractionState.previousWindowZOrders.containsKey(window.asset.id)
        ? () => actions.restorePreviousWindowZOrder(window.asset.id)
        : null;
  }

  void _handleFreeformWindowTap(AssetWindowState window) {
    if (windowInteractionState.pinnedHoverWindowId == window.asset.id) {
      actions.clearPinnedHoverWindow();
      return;
    }
    actions.clearPinnedHoverWindow();
    actions.focusWindow(window.asset.id);
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
    SerenityWorkspaceCanvasViewModel canvasViewModel,
    AssetWindowState window,
    Size viewportSize,
  ) {
    final workspace = canvasViewModel.workspace;
    final screenOffset = workspaceScreenOffsetForWindow(workspace, window, viewportSize);
    final isLoaded = _isWindowLoaded(canvasViewModel.loadPlan, window);
    final sharedVideoState = sharedVideoLookup(window, isLoaded: isLoaded);
    final windowViewModel = SerenityWindowFrameViewModel(
      window: window,
      isLoaded: isLoaded,
      sharedVideoController: sharedVideoState?.controller,
      sharedVideoInitialization: sharedVideoState?.initialization,
      isFocused: window.asset.id == canvasViewModel.focusedWindowId,
      isSelected: windowInteractionState.selectedExposeWindowIds.contains(window.asset.id),
      isPinnedHover: windowInteractionState.pinnedHoverWindowId == window.asset.id,
      workspaceZoom: workspace.viewportZoom,
      flashNonce: window.asset.id == windowInteractionState.flashedWindowId
          ? windowInteractionState.windowFlashNonce
          : 0,
      isVideoPaused: actions.isVideoWindowPaused(window.asset.id),
      isOptionGestureTarget: windowInteractionState.optionGestureWindowId == window.asset.id,
    );

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
            viewModel: windowViewModel,
            onTap: () => _handleFreeformWindowTap(window),
            onPinnedHoverRequested: () => actions.setPinnedHoverWindow(window.asset.id),
            onPinnedHoverDismissed: actions.clearPinnedHoverWindow,
            onToggleSelected: () => actions.toggleExposeWindowSelected(window.asset.id),
            onPanUpdate: (delta) => actions.moveWindow(window.asset.id, delta / workspace.viewportZoom),
            onTrackpadWindowScale: (scaleDelta, localFocalPoint) => actions.transformWindowFromTrackpad(
              window.asset.id,
              scaleDelta,
              localFocalPoint / workspace.viewportZoom,
            ),
            onResizeUpdate: (handle, delta) =>
                actions.resizeWindow(window.asset.id, handle, delta / workspace.viewportZoom),
            onZoomChanged: (update) => actions.setWindowZoom(window.asset.id, update),
            onIntrinsicSizeResolved: (size) => actions.setWindowIntrinsicSize(window.asset.id, size),
            onVideoPositionChanged: (positionMs) => actions.setVideoPosition(window.asset.id, positionMs),
            onCycleVideoPlaybackSpeed: () => actions.cycleVideoPlaybackSpeed(window.asset.id),
            onTogglePlayback: () => actions.toggleVideoPlayback(window.asset.id),
            onFitToContent: () => actions.fitWindowToContent(window.asset.id),
            onShowInFinder: _showInFinderCallbackForWindow(window),
            onRestorePreviousZOrder: _restorePreviousZOrderCallbackForWindow(window),
            onClose: () => actions.removeWindow(session.activeWorkspaceId, window.asset.id),
            onOptionGestureWindowRequested: () => actions.setOptionGestureWindowId(window.asset.id),
            onOptionGestureReleased: () => actions.setOptionGestureWindowId(null),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformWorkspaceViewport(SerenityWorkspaceCanvasViewModel canvasViewModel) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          actions.trackViewportSize(viewportSize);
          final workspace = canvasViewModel.workspace;

          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: (event) => actions.handleOptionGestureHover(event, workspace),
            onPointerPanZoomStart: (event) => actions.handleWorkspacePanZoomStart(event, workspace),
            onPointerPanZoomUpdate: (event) => actions.handleWorkspacePanZoomUpdate(event, workspace, viewportSize),
            onPointerPanZoomEnd: (_) => actions.handleWorkspacePanZoomEnd(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: actions.clearPinnedHoverWindow,
                    child: const SizedBox.expand(),
                  ),
                ),
                for (final window in canvasViewModel.windows)
                  _buildFreeformWindow(canvasViewModel, window, viewportSize),
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
    final sharedVideoState = sharedVideoLookup(window, isLoaded: isLoaded);

    return Positioned.fromRect(
      rect: layout.rect,
      child: ExposeWindowCard(
        window: window,
        isLoaded: isLoaded,
        sharedVideoController: sharedVideoState?.controller,
        sharedVideoInitialization: sharedVideoState?.initialization,
        isVideoPaused: actions.isVideoWindowPaused(window.asset.id),
        isSelected: windowInteractionState.selectedExposeWindowIds.contains(window.asset.id),
        editMode: chromeState.editMode,
        onOpen: () {
          actions.focusWindow(window.asset.id);
          actions.toggleExpose();
          actions.flashWindow(window.asset.id);
        },
        onToggleSelected: () => actions.toggleExposeWindowSelected(window.asset.id),
        onShowInFinder: _showInFinderCallbackForWindow(window),
        onRemove: () => actions.removeWindow(session.activeWorkspaceId, window.asset.id),
      ),
    );
  }

  Widget _buildExposeWorkspaceViewport(List<AssetWindowState> windows, SerenityLoadPlan loadPlan) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          actions.trackViewportSize(viewportSize);

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

  Widget _buildWorkspaceCanvasLayers(BuildContext context, SerenityWorkspaceCanvasViewModel canvasViewModel) {
    return Stack(
      children: [
        _buildWorkspaceCanvasBackground(),
        if (canvasViewModel.isExposeMode)
          _buildExposeWorkspaceViewport(canvasViewModel.windows, canvasViewModel.loadPlan)
        else
          _buildFreeformWorkspaceViewport(canvasViewModel),
        if (!canvasViewModel.isExposeMode && canvasViewModel.windows.isEmpty)
          Positioned.fill(child: _buildEmptyWorkspaceCanvasState(context)),
        if (canvasViewModel.isDropTargetActive) _buildWorkspaceDropOverlay(),
        Positioned(left: 18, bottom: 18, child: workspaceHud),
      ],
    );
  }

  Widget _buildWorkspaceCanvas(BuildContext context, WorkspaceState workspace) {
    final canvasViewModel = _buildWorkspaceCanvasViewModel(workspace);

    return DropTarget(
      onDragEntered: (_) => actions.setDropTargetActive(true),
      onDragExited: (_) => actions.setDropTargetActive(false),
      onDragDone: (details) async {
        actions.setDropTargetActive(false);
        await actions.importFiles(details.files);
      },
      child: _buildWorkspaceCanvasLayers(context, canvasViewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (openWorkspaces.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeWorkspaceId = session.activeWorkspaceId;
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

import 'dart:async';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/asset_window.dart';
import 'package:serenity_viewer/src/asset_window/frame/asset_window_resize_helpers.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_zoom_update.dart';
import 'package:serenity_viewer/src/asset_window/presentation/asset_window_view_model.dart';
import 'package:serenity_viewer/src/asset_window/presentation/expose_asset_window_card.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_projection.dart';
import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/workspace/canvas/workspace_canvas_view_model.dart';
import 'package:serenity_viewer/src/environment/workspace_asset.dart';
import 'package:serenity_viewer/src/environment/workspace_state.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/expose/expose_layouts.dart';

typedef SharedVideoLookup = SharedVideoState? Function(WorkspaceWindowState window, {required bool isLoaded});

@immutable
class WorkspaceScreenActions {
  const WorkspaceScreenActions({
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
  final void Function(String windowId, AssetWindowResizeHandle handle, Offset delta) resizeWindow;
  final void Function(String windowId, double scaleDelta, Offset localFocalPoint) transformWindowFromTrackpad;
  final ValueChanged<String> fitWindowToContent;
  final void Function(String windowId, AssetWindowZoomUpdate update) setWindowZoom;
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

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({
    super.key,
    required this.environment,
    required this.openWorkspaces,
    required this.chromeState,
    required this.windowInteractionState,
    required this.loadPlan,
    required this.sharedVideoLookup,
    required this.actions,
    required this.workspaceHud,
  });

  final Environment environment;
  final List<WorkspaceState> openWorkspaces;
  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final MediaLoadPlan loadPlan;
  final SharedVideoLookup sharedVideoLookup;
  final WorkspaceScreenActions actions;
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
                Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                const SizedBox(height: 12),
                Text(
                  'Empty workspace',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag and drop media here',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isExposeModeForWorkspace(WorkspaceState workspace) {
    return workspace.id == environment.activeWorkspaceId &&
        chromeState.screen == SerenityScreen.workspace &&
        chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
  }

  List<WorkspaceWindowState> _sortedWorkspaceWindows(WorkspaceState workspace, {required bool isExposeMode}) {
    final windows = [...workspace.windows];
    if (isExposeMode) {
      windows.sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
    } else {
      windows.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    }
    return windows;
  }

  String? _focusedWindowIdForCanvas(List<WorkspaceWindowState> windows, {required bool isExposeMode}) {
    if (windows.isEmpty || isExposeMode) {
      return null;
    }
    return windows.last.asset.id;
  }

  WorkspaceCanvasViewModel _buildWorkspaceCanvasViewModel(WorkspaceState workspace) {
    final isExposeMode = _isExposeModeForWorkspace(workspace);
    final windows = _sortedWorkspaceWindows(workspace, isExposeMode: isExposeMode);
    return WorkspaceCanvasViewModel(
      workspace: workspace,
      isExposeMode: isExposeMode,
      windows: windows,
      focusedWindowId: _focusedWindowIdForCanvas(windows, isExposeMode: isExposeMode),
      loadPlan: loadPlan,
      isDropTargetActive: chromeState.isDropTargetActive,
    );
  }

  bool _isWindowLoaded(MediaLoadPlan loadPlan, WorkspaceWindowState window) {
    return loadPlan.loadedAssetIds.contains(window.asset.id);
  }

  VoidCallback? _showInFinderCallbackForWindow(WorkspaceWindowState window) {
    return window.asset.filePath == null ? null : () => unawaited(actions.revealAssetInFinder(window.asset));
  }

  VoidCallback? _restorePreviousZOrderCallbackForWindow(WorkspaceWindowState window) {
    return windowInteractionState.previousWindowZOrders.containsKey(window.asset.id)
        ? () => actions.restorePreviousWindowZOrder(window.asset.id)
        : null;
  }

  void _handleFreeformWindowTap(WorkspaceWindowState window) {
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
            colors: [AppTheme.background, AppTheme.backgroundShade],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformWindow(
    WorkspaceCanvasViewModel canvasViewModel,
    WorkspaceWindowState window,
    Size viewportSize,
  ) {
    final workspace = canvasViewModel.workspace;
    final screenOffset = workspaceScreenOffsetForWindow(workspace, window, viewportSize);
    final isLoaded = _isWindowLoaded(canvasViewModel.loadPlan, window);
    final sharedVideoState = sharedVideoLookup(window, isLoaded: isLoaded);
    final windowViewModel = AssetWindowViewModel(
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
          child: AssetWindow(
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
            onClose: () => actions.removeWindow(environment.activeWorkspaceId, window.asset.id),
            onOptionGestureWindowRequested: () => actions.setOptionGestureWindowId(window.asset.id),
            onOptionGestureReleased: () => actions.setOptionGestureWindowId(null),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformWorkspaceViewport(WorkspaceCanvasViewModel canvasViewModel) {
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

  Widget _buildExposeAssetWindowCard(SerenityWindowLayout layout, MediaLoadPlan loadPlan) {
    final window = layout.window;
    final isLoaded = _isWindowLoaded(loadPlan, window);
    final sharedVideoState = sharedVideoLookup(window, isLoaded: isLoaded);

    return Positioned.fromRect(
      rect: layout.rect,
      child: ExposeAssetWindowCard(
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
        onRemove: () => actions.removeWindow(environment.activeWorkspaceId, window.asset.id),
      ),
    );
  }

  Widget _buildExposeWorkspaceViewport(List<WorkspaceWindowState> windows, MediaLoadPlan loadPlan) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          actions.trackViewportSize(viewportSize);

          if (windows.isEmpty) {
            return const SizedBox.shrink();
          }

          final exposeLayouts = computeExposeLayoutRects(windows: windows, viewportSize: viewportSize);
          return Stack(children: [for (final layout in exposeLayouts) _buildExposeAssetWindowCard(layout, loadPlan)]);
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

  Widget _buildWorkspaceCanvasLayers(BuildContext context, WorkspaceCanvasViewModel canvasViewModel) {
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

    final activeWorkspaceId = environment.activeWorkspaceId;
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

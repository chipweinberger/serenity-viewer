import 'dart:async';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/window/workspace_window.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/window/presentation/expose_window_card.dart';
import 'package:serenity_viewer/src/window/presentation/workspace_window_view_model.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/app_theme.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_expose_layout.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_projection.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

typedef SharedVideoLookup = SharedVideoState? Function(Window window, {required bool shouldCreate});

@immutable
class _WorkspaceCanvasViewModel {
  const _WorkspaceCanvasViewModel({
    required this.workspace,
    required this.isExposeMode,
    required this.windows,
    required this.focusedWindowId,
    required this.loadPlan,
    required this.isDropTargetActive,
  });

  final Workspace workspace;
  final bool isExposeMode;
  final List<Window> windows;
  final String? focusedWindowId;
  final MediaLoadPlan loadPlan;
  final bool isDropTargetActive;
}

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({
    super.key,
    required this.environment,
    required this.appUiState,
    required this.windowInteractionState,
    required this.workspaceViewportState,
    required this.loadPlan,
    required this.sharedVideoLookup,
    required this.workspaceController,
    required this.environmentController,
    required this.appUiController,
    required this.appUiHandles,
    required this.platformBridge,
    required this.mounted,
    required this.workspaceHud,
  });

  final Environment environment;
  final AppUiState appUiState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewportState workspaceViewportState;
  final MediaLoadPlan loadPlan;
  final SharedVideoLookup sharedVideoLookup;
  final WorkspaceController workspaceController;
  final EnvironmentController environmentController;
  final AppUiController appUiController;
  final AppUiHandles appUiHandles;
  final PlatformBridge platformBridge;
  final bool Function() mounted;
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

  bool _isExposeModeForWorkspace(Workspace workspace) {
    return workspace.id == environment.activeWorkspaceId &&
        appUiState.screen == SerenityScreen.workspace &&
        appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
  }

  List<Window> _sortedWorkspaceWindows(Workspace workspace, {required bool isExposeMode}) {
    final windows = [...workspace.windows];
    if (isExposeMode) {
      windows.sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
    } else {
      windows.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    }
    return windows;
  }

  String? _focusedWindowIdForCanvas(List<Window> windows, {required bool isExposeMode}) {
    if (windows.isEmpty || isExposeMode) {
      return null;
    }
    return windows.last.asset.id;
  }

  _WorkspaceCanvasViewModel _buildWorkspaceCanvasViewModel(Workspace workspace) {
    final isExposeMode = _isExposeModeForWorkspace(workspace);
    final windows = _sortedWorkspaceWindows(workspace, isExposeMode: isExposeMode);
    return _WorkspaceCanvasViewModel(
      workspace: workspace,
      isExposeMode: isExposeMode,
      windows: windows,
      focusedWindowId: _focusedWindowIdForCanvas(windows, isExposeMode: isExposeMode),
      loadPlan: loadPlan,
      isDropTargetActive: appUiState.isDropTargetActive,
    );
  }

  bool _isWindowLoaded(MediaLoadPlan loadPlan, Window window) {
    return loadPlan.loadedAssetIds.contains(window.asset.id);
  }

  VoidCallback? _showInFinderCallbackForWindow(Window window) {
    return window.asset.filePath == null ? null : () => unawaited(platformBridge.revealAssetInFinder(window.asset));
  }

  VoidCallback? _restorePreviousZOrderCallbackForWindow(Window window) {
    return windowInteractionState.previousWindowZOrders.containsKey(window.asset.id)
        ? () => workspaceController.window.restorePreviousWindowZOrder(window.asset.id)
        : null;
  }

  void _updateWindowTabDropTarget(String sourceWorkspaceId, Offset globalPosition) {
    appUiController.beginWindowDrag(sourceWorkspaceId);
    final targetWorkspaceId = appUiHandles.workspaceTabAt(globalPosition, excludingWorkspaceId: sourceWorkspaceId);
    appUiController.setWindowDragTargetWorkspaceId(targetWorkspaceId);
  }

  Future<void> _handleWindowDragEnd(Window window, String sourceWorkspaceId, Offset globalPosition) async {
    final targetWorkspaceId = appUiHandles.workspaceTabAt(globalPosition, excludingWorkspaceId: sourceWorkspaceId);
    appUiController.endWindowDrag();
    if (targetWorkspaceId == null) {
      return;
    }

    await environmentController.management.moveWindowToWorkspace(window.asset.id, targetWorkspaceId);
  }

  void _handleFreeformWindowTap(Window window) {
    if (windowInteractionState.pinnedHoverWindowId == window.asset.id) {
      workspaceController.window.clearPinnedHoverWindow();
      return;
    }
    workspaceController.window.clearPinnedHoverWindow();
    workspaceController.window.focusWindow(window.asset.id);
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

  bool _isWorkspaceVisible(Workspace workspace) {
    return appUiState.screen == SerenityScreen.workspace && workspace.id == environment.activeWorkspaceId;
  }

  bool _isVideoTemporarilyPaused(Workspace workspace, String windowId) {
    return !_isWorkspaceVisible(workspace) || workspaceController.playback.isVideoWindowPaused(windowId);
  }

  bool _shouldCreateSharedVideoController(_WorkspaceCanvasViewModel canvasViewModel, Window window) {
    if (!_isWindowLoaded(canvasViewModel.loadPlan, window) || window.asset.type != AssetType.video) {
      return false;
    }

    final isPaused = _isVideoTemporarilyPaused(canvasViewModel.workspace, window.asset.id);
    if (!isPaused) {
      return true;
    }

    return window.asset.id == canvasViewModel.focusedWindowId ||
        window.asset.id == windowInteractionState.pinnedHoverWindowId;
  }

  Widget _buildFreeformWindow(_WorkspaceCanvasViewModel canvasViewModel, Window window, Size viewportSize) {
    final workspace = canvasViewModel.workspace;
    final screenOffset = workspaceScreenOffsetForWindow(workspace, window, viewportSize);
    final isLoaded = _isWindowLoaded(canvasViewModel.loadPlan, window);
    final sharedVideoState = sharedVideoLookup(
      window,
      shouldCreate: _shouldCreateSharedVideoController(canvasViewModel, window),
    );
    final windowViewModel = WorkspaceWindowViewModel(
      window: window,
      isLoaded: isLoaded,
      sharedVideoController: sharedVideoState?.controller,
      sharedVideoInitialization: sharedVideoState?.initialization,
      isFocused: window.asset.id == canvasViewModel.focusedWindowId,
      isSelected: windowInteractionState.selectedExposeWindowIds.contains(window.asset.id),
      areControlsPinned: windowInteractionState.pinnedHoverWindowId == window.asset.id,
      workspaceZoom: workspace.viewportZoom,
      flashNonce: window.asset.id == windowInteractionState.flashedWindowId
          ? windowInteractionState.windowFlashNonce
          : 0,
      isVideoPaused: _isVideoTemporarilyPaused(workspace, window.asset.id),
      isCommandPressed: windowInteractionState.isCommandPressed,
      isOptionPressed: windowInteractionState.isOptionPressed,
      isOptionGestureTarget: windowInteractionState.activeGestureWindowId == window.asset.id,
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
          child: WorkspaceWindow(
            viewModel: windowViewModel,
            onTap: () => _handleFreeformWindowTap(window),
            onPinnedHoverRequested: () => workspaceController.window.setPinnedHoverWindow(window.asset.id),
            onPinnedHoverDismissed: workspaceController.window.clearPinnedHoverWindow,
            onToggleSelected: () => environmentController.navigation.toggleSelectedWindow(window.asset.id),
            onPanUpdate: (delta, globalPosition) {
              workspaceController.window.moveWindow(window.asset.id, delta / workspace.viewportZoom);
              _updateWindowTabDropTarget(workspace.id, globalPosition);
            },
            onPanEnd: (globalPosition) => _handleWindowDragEnd(window, workspace.id, globalPosition),
            onTrackpadWindowScale: (scaleDelta, globalPointerPosition) => workspaceController.window
                .transformWindowFromTrackpad(window.asset.id, scaleDelta, globalPointerPosition),
            onResizeUpdate: (handle, delta) =>
                workspaceController.window.resizeWindow(window.asset.id, handle, delta / workspace.viewportZoom),
            onZoomChanged: (update) => workspaceController.window.setWindowZoom(window.asset.id, update),
            onIntrinsicSizeResolved: (size) => workspaceController.window.setWindowIntrinsicSize(window.asset.id, size),
            onVideoPositionChanged: (positionMs) =>
                workspaceController.playback.setVideoPosition(window.asset.id, positionMs),
            onCycleVideoPlaybackSpeed: () => workspaceController.playback.cycleVideoPlaybackSpeed(window.asset.id),
            onTogglePlayback: (positionMs) =>
                workspaceController.playback.toggleVideoPlayback(window.asset.id, positionMs: positionMs),
            onFitToContent: () => workspaceController.window.fitWindowToContent(window.asset.id),
            onShowInFinder: _showInFinderCallbackForWindow(window),
            onRestorePreviousZOrder: _restorePreviousZOrderCallbackForWindow(window),
            onClose: () => environmentController.history.removeWindow(environment.activeWorkspaceId, window.asset.id),
            onOptionGestureWindowRequested: () => workspaceController.window.setActiveGestureWindow(window.asset.id),
            onOptionGestureReleased: () => workspaceController.window.setActiveGestureWindow(null),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeformWorkspaceViewport(_WorkspaceCanvasViewModel canvasViewModel) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          workspaceViewportState.setViewportSize(viewportSize);
          final workspace = canvasViewModel.workspace;

          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: (event) => workspaceController.window.handleOptionGestureHover(event, workspace),
            onPointerPanZoomStart: (event) =>
                workspaceController.viewport.handleWorkspacePanZoomStart(event, workspace),
            onPointerPanZoomUpdate: (event) =>
                workspaceController.viewport.handleWorkspacePanZoomUpdate(event, workspace, viewportSize),
            onPointerPanZoomEnd: (_) => workspaceController.viewport.handleWorkspacePanZoomEnd(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: workspaceController.window.clearPinnedHoverWindow,
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

  Widget _buildExposeWindowCard(Workspace workspace, WorkspaceExposeWindowLayout layout, MediaLoadPlan loadPlan) {
    final window = layout.window;
    final isLoaded = _isWindowLoaded(loadPlan, window);
    final sharedVideoState = sharedVideoLookup(
      window,
      shouldCreate: !_isVideoTemporarilyPaused(workspace, window.asset.id),
    );

    return Positioned.fromRect(
      rect: layout.rect,
      child: ExposeWindowCard(
        window: window,
        isLoaded: isLoaded,
        sharedVideoController: sharedVideoState?.controller,
        sharedVideoInitialization: sharedVideoState?.initialization,
        isVideoPaused: _isVideoTemporarilyPaused(workspace, window.asset.id),
        isSelected: windowInteractionState.selectedExposeWindowIds.contains(window.asset.id),
        isCommandPressed: windowInteractionState.isCommandPressed,
        editMode: appUiState.editMode,
        onOpen: () {
          workspaceController.window.focusWindow(window.asset.id);
          appUiController.toggleExpose();
          workspaceController.window.flashWindow(window.asset.id, mounted: mounted());
        },
        onToggleSelected: () => environmentController.navigation.toggleSelectedWindow(window.asset.id),
        onShowInFinder: _showInFinderCallbackForWindow(window),
        onRemove: () => environmentController.history.removeWindow(environment.activeWorkspaceId, window.asset.id),
      ),
    );
  }

  Widget _buildExposeWorkspaceViewport(Workspace workspace, List<Window> windows, MediaLoadPlan loadPlan) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          workspaceViewportState.setViewportSize(viewportSize);

          if (windows.isEmpty) {
            return const SizedBox.shrink();
          }

          final exposeLayouts = buildWorkspaceExposeLayouts(windows: windows, viewportSize: viewportSize);
          return Stack(
            children: [for (final layout in exposeLayouts) _buildExposeWindowCard(workspace, layout, loadPlan)],
          );
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

  Widget _buildWorkspaceLoadingIndicator(BuildContext context, {required int assetCount}) {
    final label = assetCount == 1 ? 'Loading 1 asset…' : 'Loading $assetCount assets…';

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceCanvasLayers(BuildContext context, _WorkspaceCanvasViewModel canvasViewModel) {
    final importAssetCount = appUiState.workspaceImportAssetCount;
    final showsLoadingIndicator = appUiState.isWorkspaceImporting && importAssetCount > 0;

    return Stack(
      children: [
        _buildWorkspaceCanvasBackground(),
        if (canvasViewModel.isExposeMode)
          _buildExposeWorkspaceViewport(canvasViewModel.workspace, canvasViewModel.windows, canvasViewModel.loadPlan)
        else
          _buildFreeformWorkspaceViewport(canvasViewModel),
        if (!canvasViewModel.isExposeMode && canvasViewModel.windows.isEmpty)
          Positioned.fill(child: _buildEmptyWorkspaceCanvasState(context)),
        if (canvasViewModel.isDropTargetActive) _buildWorkspaceDropOverlay(),
        if (showsLoadingIndicator) _buildWorkspaceLoadingIndicator(context, assetCount: importAssetCount),
        Positioned(left: 18, bottom: 18, child: workspaceHud),
      ],
    );
  }

  Widget _buildWorkspaceCanvas(BuildContext context, Workspace workspace) {
    final canvasViewModel = _buildWorkspaceCanvasViewModel(workspace);

    return DropTarget(
      onDragEntered: (_) => appUiState.setDropTargetActive(true),
      onDragExited: (_) => appUiState.setDropTargetActive(false),
      onDragDone: (details) async {
        appUiState.setDropTargetActive(false);
        await workspaceController.media.importFiles(details.files);
      },
      child: _buildWorkspaceCanvasLayers(context, canvasViewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openWorkspaces = environment.workspaces.where((workspace) => workspace.isOpen).toList();
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

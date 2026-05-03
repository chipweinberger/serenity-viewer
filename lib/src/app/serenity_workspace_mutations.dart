import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/core/serenity_core.dart';
import 'package:serenity_viewer/src/models/asset_window_state.dart';
import 'package:serenity_viewer/src/models/serenity_session_state.dart';
import 'package:serenity_viewer/src/models/window_zoom_update.dart';
import 'package:serenity_viewer/src/models/workspace_state.dart';
import 'package:serenity_viewer/src/widgets/serenity_media_zoom_utils.dart';
import 'package:serenity_viewer/src/widgets/window_resize_helpers.dart';

class SerenityWorkspaceMutations {
  static const List<double> videoPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0];
  static const double minWindowWidth = 96.0;
  static const double minWindowHeight = 72.0;
  static const double maxContentZoom = 30.0;

  static WorkspaceState? _workspaceById(SerenitySessionState session, String workspaceId) {
    return session.workspaces.where((workspace) => workspace.id == workspaceId).firstOrNull;
  }

  static AssetWindowState? _windowById(WorkspaceState workspace, String windowId) {
    return workspace.windows.where((window) => window.asset.id == windowId).firstOrNull;
  }

  static WorkspaceState _mapWindows(
    WorkspaceState workspace,
    AssetWindowState Function(AssetWindowState window) transform,
  ) {
    return workspace.copyWith(windows: workspace.windows.map(transform).toList());
  }

  static WorkspaceState _updateWindowById(
    WorkspaceState workspace,
    String windowId,
    AssetWindowState Function(AssetWindowState window) transform,
  ) {
    return _mapWindows(workspace, (window) => window.asset.id == windowId ? transform(window) : window);
  }

  static ({double left, double top, double right, double bottom}) _windowEdges(AssetWindowState window) {
    return (
      left: window.position.dx,
      top: window.position.dy,
      right: window.position.dx + window.size.width,
      bottom: window.position.dy + window.size.height,
    );
  }

  static ({double left, double top, double right, double bottom}) _applyResizeDelta(
    ({double left, double top, double right, double bottom}) edges,
    WindowResizeHandle handle,
    Offset delta,
  ) {
    var left = edges.left;
    var top = edges.top;
    var right = edges.right;
    var bottom = edges.bottom;

    switch (handle) {
      case WindowResizeHandle.left:
        left += delta.dx;
        break;
      case WindowResizeHandle.right:
        right += delta.dx;
        break;
      case WindowResizeHandle.top:
        top += delta.dy;
        break;
      case WindowResizeHandle.bottom:
        bottom += delta.dy;
        break;
      case WindowResizeHandle.topLeft:
        left += delta.dx;
        top += delta.dy;
        break;
      case WindowResizeHandle.topRight:
        right += delta.dx;
        top += delta.dy;
        break;
      case WindowResizeHandle.bottomLeft:
        left += delta.dx;
        bottom += delta.dy;
        break;
      case WindowResizeHandle.bottomRight:
        right += delta.dx;
        bottom += delta.dy;
        break;
    }

    return (left: left, top: top, right: right, bottom: bottom);
  }

  static bool _resizesFromLeft(WindowResizeHandle handle) {
    return {WindowResizeHandle.left, WindowResizeHandle.topLeft, WindowResizeHandle.bottomLeft}.contains(handle);
  }

  static bool _resizesFromTop(WindowResizeHandle handle) {
    return {WindowResizeHandle.top, WindowResizeHandle.topLeft, WindowResizeHandle.topRight}.contains(handle);
  }

  static ({Offset position, Size size}) _clampResizedBounds(
    ({double left, double top, double right, double bottom}) edges,
    WindowResizeHandle handle,
  ) {
    var left = edges.left;
    var top = edges.top;
    var right = edges.right;
    var bottom = edges.bottom;

    var width = right - left;
    if (width < minWindowWidth) {
      if (_resizesFromLeft(handle)) {
        left = right - minWindowWidth;
      } else {
        right = left + minWindowWidth;
      }
      width = minWindowWidth;
    }

    var height = bottom - top;
    if (height < minWindowHeight) {
      if (_resizesFromTop(handle)) {
        top = bottom - minWindowHeight;
      } else {
        bottom = top + minWindowHeight;
      }
      height = minWindowHeight;
    }

    width = width.clamp(minWindowWidth, workspaceExtent * 2);
    height = height.clamp(minWindowHeight, workspaceExtent * 2);
    left = left.clamp(workspaceMinCoordinate, workspaceMaxCoordinate - width);
    top = top.clamp(workspaceMinCoordinate, workspaceMaxCoordinate - height);

    return (position: Offset(left, top), size: Size(width, height));
  }

  static Rect _workspaceContentBounds(List<AssetWindowState> windows) {
    var minX = windows.first.position.dx;
    var minY = windows.first.position.dy;
    var maxX = windows.first.position.dx + windows.first.size.width;
    var maxY = windows.first.position.dy + windows.first.size.height;

    for (final window in windows.skip(1)) {
      minX = math.min(minX, window.position.dx);
      minY = math.min(minY, window.position.dy);
      maxX = math.max(maxX, window.position.dx + window.size.width);
      maxY = math.max(maxY, window.position.dy + window.size.height);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static SerenitySessionState replaceWorkspace(SerenitySessionState session, WorkspaceState nextWorkspace) {
    return session.copyWith(
      workspaces: session.workspaces
          .map((workspace) => workspace.id == nextWorkspace.id ? nextWorkspace : workspace)
          .toList(),
    );
  }

  static SerenitySessionState toggleWorkspaceOpen(SerenitySessionState session, String workspaceId) {
    final nextWorkspaces = session.workspaces
        .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: !workspace.isOpen) : workspace)
        .toList();

    var nextActiveId = session.activeWorkspaceId;
    final openWorkspaces = nextWorkspaces.where((workspace) => workspace.isOpen).toList();
    if (openWorkspaces.isEmpty) {
      nextWorkspaces[0] = nextWorkspaces[0].copyWith(isOpen: true);
      nextActiveId = nextWorkspaces[0].id;
    } else if (!openWorkspaces.any((workspace) => workspace.id == nextActiveId)) {
      nextActiveId = openWorkspaces.first.id;
    }

    return session.copyWith(workspaces: nextWorkspaces, activeWorkspaceId: nextActiveId);
  }

  static List<WorkspaceState> reorderOpenWorkspaces(
    List<WorkspaceState> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
  }) {
    if (sourceWorkspaceId == targetWorkspaceId) {
      return workspaces;
    }

    final openWorkspaces = workspaces.where((workspace) => workspace.isOpen).toList();
    final sourceIndex = openWorkspaces.indexWhere((workspace) => workspace.id == sourceWorkspaceId);
    final targetIndex = openWorkspaces.indexWhere((workspace) => workspace.id == targetWorkspaceId);
    if (sourceIndex == -1 || targetIndex == -1) {
      return workspaces;
    }

    final moved = openWorkspaces.removeAt(sourceIndex);
    openWorkspaces.insert(targetIndex, moved);

    final openWorkspaceIds = openWorkspaces.map((workspace) => workspace.id).toList();
    final openWorkspaceById = {for (final workspace in openWorkspaces) workspace.id: workspace};
    var openWorkspaceCursor = 0;
    return workspaces.map((workspace) {
      if (!workspace.isOpen) {
        return workspace;
      }

      final nextWorkspaceId = openWorkspaceIds[openWorkspaceCursor++];
      return openWorkspaceById[nextWorkspaceId]!;
    }).toList();
  }

  static SerenitySessionState moveSelectedWindowsToWorkspace(
    SerenitySessionState session, {
    required String sourceWorkspaceId,
    required String destinationWorkspaceId,
    required Set<String> selectedWindowIds,
  }) {
    if (selectedWindowIds.isEmpty || sourceWorkspaceId == destinationWorkspaceId) {
      return session;
    }

    final sourceWorkspace = _workspaceById(session, sourceWorkspaceId);
    final destinationWorkspace = _workspaceById(session, destinationWorkspaceId);
    if (sourceWorkspace == null || destinationWorkspace == null) {
      return session;
    }

    final selectedWindows = sourceWorkspace.windows
        .where((window) => selectedWindowIds.contains(window.asset.id))
        .toList();
    if (selectedWindows.isEmpty) {
      return session;
    }

    var nextZ = destinationWorkspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    final movedWindows = selectedWindows.map((window) {
      nextZ += 1;
      return window.copyWith(zIndex: nextZ);
    }).toList();

    final nextWorkspaces = session.workspaces.map((workspace) {
      if (workspace.id == sourceWorkspaceId) {
        return workspace.copyWith(
          windows: workspace.windows.where((window) => !selectedWindowIds.contains(window.asset.id)).toList(),
        );
      }
      if (workspace.id == destinationWorkspaceId) {
        return workspace.copyWith(windows: [...workspace.windows, ...movedWindows], isOpen: true);
      }
      return workspace;
    }).toList();

    return session.copyWith(workspaces: nextWorkspaces);
  }

  static ({WorkspaceState workspace, int? previousZOrder}) focusWindow(WorkspaceState workspace, String windowId) {
    final currentWindow = _windowById(workspace, windowId);
    if (currentWindow == null) {
      return (workspace: workspace, previousZOrder: null);
    }

    final maxZ = workspace.windows.fold<int>(0, (value, window) => math.max(value, window.zIndex));
    if (currentWindow.zIndex == maxZ) {
      return (workspace: workspace, previousZOrder: null);
    }

    return (
      workspace: _updateWindowById(workspace, windowId, (window) => window.copyWith(zIndex: maxZ + 1)),
      previousZOrder: currentWindow.zIndex,
    );
  }

  static WorkspaceState restorePreviousWindowZOrder(WorkspaceState workspace, String windowId, int previousZOrder) {
    final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final currentIndex = sortedWindows.indexWhere((window) => window.asset.id == windowId);
    if (currentIndex == -1) {
      return workspace;
    }

    final targetWindow = sortedWindows.removeAt(currentIndex);
    var insertIndex = sortedWindows.indexWhere((window) => window.zIndex > previousZOrder);
    if (insertIndex == -1) {
      insertIndex = sortedWindows.length;
    }
    sortedWindows.insert(insertIndex, targetWindow);

    final reindexedWindows = sortedWindows
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(zIndex: entry.key + 1))
        .toList();
    final reindexedById = {for (final window in reindexedWindows) window.asset.id: window};

    return workspace.copyWith(
      windows: workspace.windows.map((window) => reindexedById[window.asset.id] ?? window).toList(),
    );
  }

  static double clampWorkspaceZoom(double zoom) {
    return zoom.clamp(workspaceMinZoom, workspaceMaxZoom);
  }

  static Offset clampWorkspaceCenter({required Offset center, required double zoom, required Size viewportSize}) {
    final safeZoom = clampWorkspaceZoom(zoom);
    final halfVisibleWidth = viewportSize.width <= 0 ? 0.0 : viewportSize.width / (2 * safeZoom);
    final halfVisibleHeight = viewportSize.height <= 0 ? 0.0 : viewportSize.height / (2 * safeZoom);

    final minCenterX = halfVisibleWidth >= workspaceExtent ? 0.0 : workspaceMinCoordinate + halfVisibleWidth;
    final maxCenterX = halfVisibleWidth >= workspaceExtent ? 0.0 : workspaceMaxCoordinate - halfVisibleWidth;
    final minCenterY = halfVisibleHeight >= workspaceExtent ? 0.0 : workspaceMinCoordinate + halfVisibleHeight;
    final maxCenterY = halfVisibleHeight >= workspaceExtent ? 0.0 : workspaceMaxCoordinate - halfVisibleHeight;

    return Offset(center.dx.clamp(minCenterX, maxCenterX), center.dy.clamp(minCenterY, maxCenterY));
  }

  static WorkspaceState setWorkspaceViewport(
    WorkspaceState workspace, {
    required Size viewportSize,
    Offset? center,
    double? zoom,
  }) {
    final nextZoom = clampWorkspaceZoom(zoom ?? workspace.viewportZoom);
    final nextCenter = clampWorkspaceCenter(
      center: center ?? workspace.viewportCenter,
      zoom: nextZoom,
      viewportSize: viewportSize,
    );

    return workspace.copyWith(viewportCenterDx: nextCenter.dx, viewportCenterDy: nextCenter.dy, viewportZoom: nextZoom);
  }

  static Offset clampWindowPosition(Offset position, Size size) {
    return Offset(
      position.dx.clamp(workspaceMinCoordinate, math.max(workspaceMinCoordinate, workspaceMaxCoordinate - size.width)),
      position.dy.clamp(workspaceMinCoordinate, math.max(workspaceMinCoordinate, workspaceMaxCoordinate - size.height)),
    );
  }

  static Size windowSizeByFittingAspect({
    required Size currentSize,
    required double contentWidth,
    required double contentHeight,
  }) {
    if (contentWidth <= 0 || contentHeight <= 0) {
      return currentSize;
    }

    final aspectRatio = contentWidth / contentHeight;
    final currentAspectRatio = currentSize.width / currentSize.height;

    if (currentAspectRatio > aspectRatio) {
      final nextWidth = math.max(minWindowWidth, currentSize.height * aspectRatio);
      return Size(math.min(currentSize.width, nextWidth), currentSize.height);
    }

    if (currentAspectRatio < aspectRatio) {
      final nextHeight = math.max(minWindowHeight, currentSize.width / aspectRatio);
      return Size(currentSize.width, math.min(currentSize.height, nextHeight));
    }

    return currentSize;
  }

  static WorkspaceState moveWindow(WorkspaceState workspace, String windowId, Offset delta) {
    return _updateWindowById(
      workspace,
      windowId,
      (window) => window.copyWith(position: clampWindowPosition(window.position + delta, window.size)),
    );
  }

  static AssetWindowState scaleWindowAroundCenter(
    AssetWindowState window,
    double scaleDelta, {
    required bool mirrorContentZoom,
  }) {
    final clampedScaleDelta = scaleDelta.clamp(0.5, 2.0);
    final focalWorldPoint = Offset(
      window.position.dx + (window.size.width / 2),
      window.position.dy + (window.size.height / 2),
    );
    final nextWidth = (window.size.width * clampedScaleDelta).clamp(minWindowWidth, workspaceExtent * 2).toDouble();
    final nextHeight = (window.size.height * clampedScaleDelta).clamp(minWindowHeight, workspaceExtent * 2).toDouble();
    final nextSize = Size(nextWidth, nextHeight);
    final nextPosition = clampWindowPosition(
      Offset(focalWorldPoint.dx - (nextWidth / 2), focalWorldPoint.dy - (nextHeight / 2)),
      nextSize,
    );
    final shouldScaleContentZoom = mirrorContentZoom || window.zoom > 1.0 || window.zoomBaseSize != null;
    final nextZoom = shouldScaleContentZoom
        ? (window.zoom * clampedScaleDelta).clamp(1.0, maxContentZoom).toDouble()
        : window.zoom;
    final snappedZoom = (nextZoom - 1).abs() < 0.02 ? 1.0 : nextZoom;
    final nextContentOffset = snappedZoom > 1.0 ? window.contentOffset * clampedScaleDelta : Offset.zero;
    final nextZoomBaseSize = snappedZoom > 1.0
        ? Size(
            (window.zoomBaseSize?.width ?? window.size.width) * clampedScaleDelta,
            (window.zoomBaseSize?.height ?? window.size.height) * clampedScaleDelta,
          )
        : null;

    return window.copyWith(
      position: nextPosition,
      size: nextSize,
      zoom: snappedZoom,
      zoomBaseWidth: nextZoomBaseSize?.width,
      zoomBaseHeight: nextZoomBaseSize?.height,
      contentOffsetDx: nextContentOffset.dx,
      contentOffsetDy: nextContentOffset.dy,
      clearZoomBase: snappedZoom <= 1.0,
      clearContentOffset: snappedZoom <= 1.0,
    );
  }

  static ({Rect visibleRect, Size zoomedContentSize}) visibleContentRectForWindow(AssetWindowState window) {
    final fitSize = fitSizeForViewportToAspect(window.size, window.asset.aspectRatio);
    final baseSize = window.zoom > 1.0 && window.zoomBaseSize != null ? window.zoomBaseSize! : fitSize;
    final zoomedContentSize = Size(baseSize.width * window.zoom, baseSize.height * window.zoom);
    final left = ((window.size.width - zoomedContentSize.width) / 2) + window.contentOffset.dx;
    final top = ((window.size.height - zoomedContentSize.height) / 2) + window.contentOffset.dy;
    final visibleLeft = math.max(0.0, left);
    final visibleTop = math.max(0.0, top);
    final visibleRight = math.min(window.size.width, left + zoomedContentSize.width);
    final visibleBottom = math.min(window.size.height, top + zoomedContentSize.height);

    return (
      visibleRect: Rect.fromLTRB(visibleLeft, visibleTop, visibleRight, visibleBottom),
      zoomedContentSize: zoomedContentSize,
    );
  }

  static WorkspaceState collateWorkspaceWindows(WorkspaceState workspace, {required Size targetBox}) {
    final targetCenter = workspace.viewportCenter;
    return _mapWindows(workspace, (window) {
      if (window.asset.type != AssetType.image && window.asset.type != AssetType.video) {
        return window;
      }

      final targetSize = fitSizeForViewportToAspect(targetBox, window.asset.aspectRatio);
      if (targetSize.width <= 0 || targetSize.height <= 0) {
        return window;
      }

      final centeredPosition = clampWindowPosition(
        Offset(targetCenter.dx - (targetSize.width / 2), targetCenter.dy - (targetSize.height / 2)),
        targetSize,
      );
      return window.copyWith(
        position: centeredPosition,
        size: targetSize,
        zoom: 1,
        clearZoomBase: true,
        clearContentOffset: true,
      );
    });
  }

  static ({Offset position, Size size}) _resizedBoundsForWindow(
    AssetWindowState window,
    WindowResizeHandle handle,
    Offset delta,
  ) {
    final resizedEdges = _applyResizeDelta(_windowEdges(window), handle, delta);
    return _clampResizedBounds(resizedEdges, handle);
  }

  static AssetWindowState _resizeWindowState(AssetWindowState window, WindowResizeHandle handle, Offset delta) {
    final nextBounds = _resizedBoundsForWindow(window, handle, delta);
    return window.copyWith(position: nextBounds.position, size: nextBounds.size);
  }

  static AssetWindowState _fitWindowToVisibleContent(AssetWindowState currentWindow) {
    final visibleContent = visibleContentRectForWindow(currentWindow);
    final visibleRect = visibleContent.visibleRect;
    final nextSize = Size(
      math.max(1.0, visibleRect.width).clamp(minWindowWidth, workspaceExtent * 2),
      math.max(1.0, visibleRect.height).clamp(minWindowHeight, workspaceExtent * 2),
    );
    final nextPosition = clampWindowPosition(currentWindow.position + visibleRect.topLeft, nextSize);
    final nextLeft =
        ((currentWindow.size.width - visibleContent.zoomedContentSize.width) / 2) +
        currentWindow.contentOffset.dx -
        visibleRect.left;
    final nextTop =
        ((currentWindow.size.height - visibleContent.zoomedContentSize.height) / 2) +
        currentWindow.contentOffset.dy -
        visibleRect.top;
    final nextContentOffset = Offset(
      nextLeft - ((nextSize.width - visibleContent.zoomedContentSize.width) / 2),
      nextTop - ((nextSize.height - visibleContent.zoomedContentSize.height) / 2),
    );

    return currentWindow.copyWith(
      position: nextPosition,
      size: nextSize,
      contentOffsetDx: currentWindow.zoom > 1.0 ? nextContentOffset.dx : 0,
      contentOffsetDy: currentWindow.zoom > 1.0 ? nextContentOffset.dy : 0,
      clearContentOffset: currentWindow.zoom <= 1.0,
    );
  }

  static WorkspaceState resizeWindow(
    WorkspaceState workspace,
    String windowId,
    WindowResizeHandle handle,
    Offset delta,
  ) {
    return _updateWindowById(workspace, windowId, (window) => _resizeWindowState(window, handle, delta));
  }

  static WorkspaceState transformWindowFromTrackpad(WorkspaceState workspace, String windowId, double scaleDelta) {
    return _updateWindowById(
      workspace,
      windowId,
      (window) => scaleWindowAroundCenter(window, scaleDelta, mirrorContentZoom: false),
    );
  }

  static WorkspaceState fitWindowToContent(WorkspaceState workspace, String windowId) {
    final currentWindow = _windowById(workspace, windowId);
    if (currentWindow == null) {
      return workspace;
    }

    return _updateWindowById(workspace, windowId, (_) => _fitWindowToVisibleContent(currentWindow));
  }

  static WorkspaceState fitWorkspaceViewportToContent(WorkspaceState workspace, Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0 || workspace.windows.isEmpty) {
      return setWorkspaceViewport(workspace, viewportSize: viewportSize, center: defaultWorkspaceCenter, zoom: 1);
    }

    final contentBounds = _workspaceContentBounds(workspace.windows);
    const padding = 120.0;
    final contentWidth = math.max(1.0, contentBounds.width + padding);
    final contentHeight = math.max(1.0, contentBounds.height + padding);
    final zoom = clampWorkspaceZoom(math.min(viewportSize.width / contentWidth, viewportSize.height / contentHeight));
    return setWorkspaceViewport(workspace, viewportSize: viewportSize, center: contentBounds.center, zoom: zoom);
  }

  static WorkspaceState setWindowZoom(WorkspaceState workspace, String windowId, WindowZoomUpdate update) {
    return _updateWindowById(
      workspace,
      windowId,
      (window) => window.copyWith(
        zoom: update.zoom,
        zoomBaseWidth: update.zoomBaseSize?.width,
        zoomBaseHeight: update.zoomBaseSize?.height,
        contentOffsetDx: update.contentOffset?.dx,
        contentOffsetDy: update.contentOffset?.dy,
        clearZoomBase: update.clearZoomBase,
        clearContentOffset: update.clearContentOffset,
      ),
    );
  }

  static WorkspaceState setVideoPosition(WorkspaceState workspace, String windowId, int positionMs) {
    return _updateWindowById(workspace, windowId, (window) => window.copyWith(videoPositionMs: positionMs));
  }

  static WorkspaceState cycleVideoPlaybackSpeed(WorkspaceState workspace, String windowId) {
    final currentWindow = _videoWindowById(workspace, windowId);
    if (currentWindow == null) {
      return workspace;
    }

    final currentIndex = videoPlaybackSpeeds.indexWhere(
      (speed) => (speed - currentWindow.videoPlaybackSpeed).abs() < 0.001,
    );
    final nextSpeed = videoPlaybackSpeeds[(currentIndex + 1) % videoPlaybackSpeeds.length];

    return _updateWindowById(workspace, windowId, (window) => window.copyWith(videoPlaybackSpeed: nextSpeed));
  }

  static WorkspaceState setWindowIntrinsicSize(WorkspaceState workspace, String windowId, Size intrinsicSize) {
    if (intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return workspace;
    }

    final currentWindow = _windowById(workspace, windowId);
    if (currentWindow == null) {
      return workspace;
    }

    final currentWidth = currentWindow.asset.intrinsicWidth;
    final currentHeight = currentWindow.asset.intrinsicHeight;
    final shouldAdoptContentSize =
        currentWidth == null &&
        currentHeight == null &&
        ((currentWindow.asset.type == AssetType.video && currentWindow.size == const Size(520, 340)) ||
            (currentWindow.asset.type == AssetType.image && currentWindow.size == const Size(420, 300)));
    if (currentWidth != null &&
        currentHeight != null &&
        (currentWidth - intrinsicSize.width).abs() < 0.001 &&
        (currentHeight - intrinsicSize.height).abs() < 0.001) {
      return workspace;
    }

    return _updateWindowById(workspace, windowId, (window) {
      final nextSize = shouldAdoptContentSize
          ? windowSizeByFittingAspect(
              currentSize: currentWindow.size,
              contentWidth: intrinsicSize.width,
              contentHeight: intrinsicSize.height,
            )
          : null;
      return window.copyWith(
        position: nextSize == null ? null : clampWindowPosition(window.position, nextSize),
        size: nextSize,
        zoom: shouldAdoptContentSize ? 1 : null,
        clearZoomBase: shouldAdoptContentSize,
        clearContentOffset: shouldAdoptContentSize,
        asset: window.asset.copyWith(intrinsicWidth: intrinsicSize.width, intrinsicHeight: intrinsicSize.height),
      );
    });
  }

  static AssetWindowState? _videoWindowById(WorkspaceState workspace, String windowId) {
    final window = _windowById(workspace, windowId);
    if (window == null || window.asset.type != AssetType.video) {
      return null;
    }
    return window;
  }
}

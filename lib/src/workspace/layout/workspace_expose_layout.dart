import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';

typedef WorkspaceExposeWindowLayout = ({Window window, Rect rect});

List<WorkspaceExposeWindowLayout> buildWorkspaceExposeLayouts({
  required List<Window> windows,
  required Size viewportSize,
}) {
  return _computeWorkspaceExposeLayout(windows: windows, viewportSize: viewportSize);
}

Workspace applyWorkspaceExposeGridLayout({
  required Workspace workspace,
  required Size viewportSize,
  required double appliedExposeViewportZoomFactor,
}) {
  if (viewportSize.width <= 0 || viewportSize.height <= 0 || workspace.windows.isEmpty) {
    return workspace;
  }

  final sortedWindows = [...workspace.windows]..sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
  final exposeLayouts = _computeWorkspaceExposeLayout(windows: sortedWindows, viewportSize: viewportSize);
  if (exposeLayouts.isEmpty) {
    return workspace;
  }

  final viewportCenter = viewportSize.center(Offset.zero);
  final safeViewportZoom = workspace.viewportZoom <= 0 ? 1.0 : workspace.viewportZoom;
  final nextViewportZoom = WorkspaceLayout.clampWorkspaceZoom(safeViewportZoom * appliedExposeViewportZoomFactor);
  final relaidOutById = <String, Window>{};
  for (final layout in exposeLayouts) {
    final rect = layout.rect;
    final nextSize = Size(rect.width / nextViewportZoom, rect.height / nextViewportZoom);
    final nextPosition = WorkspaceLayout.clampWindowPosition(
      Offset(
        workspace.viewportCenter.dx + ((rect.left - viewportCenter.dx) / nextViewportZoom),
        workspace.viewportCenter.dy + ((rect.top - viewportCenter.dy) / nextViewportZoom),
      ),
      nextSize,
    );
    relaidOutById[layout.window.asset.id] = layout.window.copyWith(position: nextPosition, size: nextSize);
  }

  return workspace.copyWith(
    windows: workspace.windows.map((window) => relaidOutById[window.asset.id] ?? window).toList(),
    viewportZoom: nextViewportZoom,
  );
}

List<WorkspaceExposeWindowLayout> _computeWorkspaceExposeLayout({
  required List<Window> windows,
  required Size viewportSize,
}) {
  const horizontalPadding = 28.0;
  const topPadding = 86.0;
  const bottomPadding = 92.0;
  const spacing = 10.78;
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

  final rows = <List<({Window window, double width})>>[];
  var currentRow = <({Window window, double width})>[];
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
  final layouts = <WorkspaceExposeWindowLayout>[];

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

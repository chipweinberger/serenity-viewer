import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/expose/expose_layouts.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';

class WorkspaceShellNavigationApi {
  WorkspaceShellNavigationApi(this._controller);

  static const double _appliedExposeViewportZoomFactor = 0.0625;

  final WorkspaceShellController _controller;

  void toggleSelectedWindow(String windowId) {
    _controller.workspaceController.expose.toggle(windowId);
  }

  void clearExposeSelection() {
    _controller.workspaceController.expose.clear();
  }

  void toggleOverview() {
    if (_controller.chromeState.screen == SerenityScreen.workspace) {
      unawaited(_controller.refreshActiveWorkspaceThumbnail());
    }

    if (_controller.chromeState.screen == SerenityScreen.library) {
      _controller.showWorkspaceScreen();
    } else {
      _controller.showLibraryScreen();
    }
  }

  void showOverview() {
    if (_controller.chromeState.screen == SerenityScreen.workspace) {
      unawaited(_controller.refreshActiveWorkspaceThumbnail());
    }

    _controller.showLibraryScreen();
  }

  void switchWorkspace(int direction) {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final target = _controller.workspaceSwitchTarget(
      openWorkspaces: _controller.openWorkspaces(),
      activeWorkspaceId: environment.activeWorkspaceId,
      direction: direction,
    );
    if (target.showsLibrary) {
      showOverview();
      return;
    }

    unawaited(setActiveWorkspace(target.workspaceId!));
  }

  Future<void> setActiveWorkspace(String workspaceId) async {
    final environment = _controller.persistenceState.environment;
    if (environment == null) {
      return;
    }

    final currentWorkspaceId = environment.activeWorkspaceId;
    if (currentWorkspaceId != workspaceId) {
      unawaited(_controller.refreshActiveWorkspaceThumbnail());
    }

    final shouldPreserveExpose =
        _controller.chromeState.screen == SerenityScreen.workspace &&
        _controller.chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
    _controller.updateEnvironment(
      environment.copyWith(
        activeWorkspaceId: workspaceId,
        workspaces: environment.workspaces
            .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: true) : workspace)
            .toList(),
      ),
    );

    _controller.showWorkspaceScreen(
      workspaceLayoutMode: shouldPreserveExpose ? WorkspaceLayoutMode.expose : WorkspaceLayoutMode.freeform,
    );
  }

  void applyExposeGridToWorkspace() {
    final workspace = _controller.activeWorkspace();
    if (workspace == null ||
        _controller.chromeState.screen != SerenityScreen.workspace ||
        _controller.chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
      return;
    }
    if (_controller.workspaceViewportState.viewportSize.width <= 0 ||
        _controller.workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      return;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
    final exposeLayouts = computeExposeLayoutRects(
      windows: sortedWindows,
      viewportSize: _controller.workspaceViewportState.viewportSize,
    );
    if (exposeLayouts.isEmpty) {
      return;
    }

    final viewportCenter = _controller.workspaceViewportState.viewportSize.center(Offset.zero);
    final safeViewportZoom = workspace.viewportZoom <= 0 ? 1.0 : workspace.viewportZoom;
    final nextViewportZoom = WorkspaceLayout.clampWorkspaceZoom(safeViewportZoom * _appliedExposeViewportZoomFactor);
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

    _controller.replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) => relaidOutById[window.asset.id] ?? window).toList(),
        viewportZoom: nextViewportZoom,
      ),
    );

    _controller.showWorkspaceScreen();
  }

  Future<void> confirmApplyExposeGridToWorkspace() async {
    final workspace = _controller.activeWorkspace();
    if (workspace == null ||
        _controller.chromeState.screen != SerenityScreen.workspace ||
        _controller.chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose ||
        workspace.windows.isEmpty) {
      return;
    }

    final shouldApply = await showDialog<bool>(
      context: _controller.context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Apply Grid?'),
          content: Text(
            'Replace the current freeform layout in "${workspace.name}" with this expose grid arrangement?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Apply')),
          ],
        );
      },
    );

    if (shouldApply == true && _controller.mounted()) {
      applyExposeGridToWorkspace();
    }
  }
}

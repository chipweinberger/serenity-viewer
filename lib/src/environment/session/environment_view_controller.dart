import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/expose/expose_layouts.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/environment/session/environment_api.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class EnvironmentViewDependencies {
  const EnvironmentViewDependencies({
    required this.environmentStoreState,
    required this.appUiState,
    required this.workspaceViewportState,
    required this.workspaceController,
    required this.context,
    required this.mounted,
    required this.openWorkspaces,
    required this.activeWorkspace,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.showWorkspaceScreen,
    required this.showLibraryScreen,
    required this.workspaceSwitchTarget,
    required this.refreshActiveWorkspaceThumbnail,
  });

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
  final WorkspaceViewportState workspaceViewportState;
  final WorkspaceController workspaceController;
  final BuildContext Function() context;
  final bool Function() mounted;
  final List<Workspace> Function() openWorkspaces;
  final Workspace? Function() activeWorkspace;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final SerenityShowLibraryScreen showLibraryScreen;
  final SerenityWorkspaceSwitchTargetResolver workspaceSwitchTarget;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
}

class EnvironmentViewController {
  EnvironmentViewController(this._dependencies);

  static const double _appliedExposeViewportZoomFactor = 0.0625;

  final EnvironmentViewDependencies _dependencies;

  void toggleSelectedWindow(String windowId) {
    _dependencies.workspaceController.expose.toggle(windowId);
  }

  void clearExposeSelection() {
    _dependencies.workspaceController.expose.clear();
  }

  void toggleOverview() {
    if (_dependencies.appUiState.screen == SerenityScreen.workspace) {
      unawaited(_dependencies.refreshActiveWorkspaceThumbnail());
    }

    if (_dependencies.appUiState.screen == SerenityScreen.library) {
      _dependencies.showWorkspaceScreen();
    } else {
      _dependencies.showLibraryScreen();
    }
  }

  void showOverview() {
    if (_dependencies.appUiState.screen == SerenityScreen.workspace) {
      unawaited(_dependencies.refreshActiveWorkspaceThumbnail());
    }

    _dependencies.showLibraryScreen();
  }

  void switchWorkspace(int direction) {
    final environment = _dependencies.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    final target = _dependencies.workspaceSwitchTarget(
      openWorkspaces: _dependencies.openWorkspaces(),
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
    final environment = _dependencies.environmentStoreState.environment;
    if (environment == null) {
      return;
    }

    final currentWorkspaceId = environment.activeWorkspaceId;
    if (currentWorkspaceId != workspaceId) {
      unawaited(_dependencies.refreshActiveWorkspaceThumbnail());
    }

    final shouldPreserveExpose =
        _dependencies.appUiState.screen == SerenityScreen.workspace &&
        _dependencies.appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose;
    _dependencies.updateEnvironment(
      environment.copyWith(
        activeWorkspaceId: workspaceId,
        workspaces: environment.workspaces
            .map((workspace) => workspace.id == workspaceId ? workspace.copyWith(isOpen: true) : workspace)
            .toList(),
      ),
    );

    _dependencies.showWorkspaceScreen(
      workspaceLayoutMode: shouldPreserveExpose ? WorkspaceLayoutMode.expose : WorkspaceLayoutMode.freeform,
    );
  }

  void applyExposeGridToWorkspace() {
    final workspace = _dependencies.activeWorkspace();
    if (workspace == null ||
        _dependencies.appUiState.screen != SerenityScreen.workspace ||
        _dependencies.appUiState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
      return;
    }
    if (_dependencies.workspaceViewportState.viewportSize.width <= 0 ||
        _dependencies.workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      return;
    }

    final sortedWindows = [...workspace.windows]..sort((a, b) => a.asset.filename.compareTo(b.asset.filename));
    final exposeLayouts = computeExposeLayoutRects(
      windows: sortedWindows,
      viewportSize: _dependencies.workspaceViewportState.viewportSize,
    );
    if (exposeLayouts.isEmpty) {
      return;
    }

    final viewportCenter = _dependencies.workspaceViewportState.viewportSize.center(Offset.zero);
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

    _dependencies.replaceWorkspace(
      workspace.copyWith(
        windows: workspace.windows.map((window) => relaidOutById[window.asset.id] ?? window).toList(),
        viewportZoom: nextViewportZoom,
      ),
    );

    _dependencies.showWorkspaceScreen();
  }

  Future<void> confirmApplyExposeGridToWorkspace() async {
    final workspace = _dependencies.activeWorkspace();
    if (workspace == null ||
        _dependencies.appUiState.screen != SerenityScreen.workspace ||
        _dependencies.appUiState.workspaceLayoutMode != WorkspaceLayoutMode.expose ||
        workspace.windows.isEmpty) {
      return;
    }

    final shouldApply = await showDialog<bool>(
      context: _dependencies.context(),
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

    if (shouldApply == true && _dependencies.mounted()) {
      applyExposeGridToWorkspace();
    }
  }
}

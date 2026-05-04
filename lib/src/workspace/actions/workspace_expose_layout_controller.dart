import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_expose_layout.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceExposeLayoutDependencies {
  const WorkspaceExposeLayoutDependencies({
    required this.appUiState,
    required this.workspaceViewportState,
    required this.context,
    required this.mounted,
    required this.activeWorkspace,
    required this.replaceWorkspace,
    required this.showWorkspaceScreen,
  });

  final AppUiState appUiState;
  final WorkspaceViewportState workspaceViewportState;
  final BuildContext Function() context;
  final bool Function() mounted;
  final Workspace? Function() activeWorkspace;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final void Function({
    WorkspaceLayoutMode workspaceLayoutMode,
    bool resetEditMode,
    bool clearExposeSelection,
    bool refreshWorkspaceTracking,
  })
  showWorkspaceScreen;
}

class WorkspaceExposeLayoutController {
  WorkspaceExposeLayoutController(this._dependencies);

  static const double _appliedExposeViewportZoomFactor = 0.0625;

  final WorkspaceExposeLayoutDependencies _dependencies;

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

    _dependencies.replaceWorkspace(
      applyWorkspaceExposeGridLayout(
        workspace: workspace,
        viewportSize: _dependencies.workspaceViewportState.viewportSize,
        appliedExposeViewportZoomFactor: _appliedExposeViewportZoomFactor,
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

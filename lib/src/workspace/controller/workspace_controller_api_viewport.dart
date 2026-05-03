import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';

class WorkspaceViewportApi {
  WorkspaceViewportApi(this._controller);

  final WorkspaceController _controller;

  void handlePanZoomStart(
    PointerPanZoomStartEvent event,
    Workspace workspace, {
    required bool isCommandPressedForContentGesture,
    required bool isOptionPressedForWindowGesture,
  }) {
    _controller.viewportController.handleWorkspacePanZoomStart(
      event,
      workspace,
      isCommandPressedForContentGesture: isCommandPressedForContentGesture,
      isOptionPressedForWindowGesture: isOptionPressedForWindowGesture,
    );
  }

  void handlePanZoomUpdate(PointerPanZoomUpdateEvent event, Workspace workspace, Size viewportSize) {
    _controller.viewportController.handleWorkspacePanZoomUpdate(event, workspace, viewportSize);
  }

  Future<void> handlePanZoomEnd() async {
    await _controller.viewportController.handleWorkspacePanZoomEnd();
  }

  void fitToContent(Workspace? workspace) {
    _controller.fitWorkspaceViewportToContent(workspace);
  }
}

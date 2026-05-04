import 'dart:async';

import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_entry.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_state.dart';

class WorkspaceWindowRuntimeController {
  const WorkspaceWindowRuntimeController({required this.windowInteractionState});

  final WindowInteractionState windowInteractionState;

  void flash(String windowId, {required bool mounted}) {
    windowInteractionState.windowFlashTimer?.cancel();
    windowInteractionState.showWindowFlash(windowId);
    windowInteractionState.windowFlashTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || windowInteractionState.flashedWindowId != windowId) {
        return;
      }
      windowInteractionState.clearWindowFlash(windowId);
    });
  }

  void clear(String windowId) {
    windowInteractionState.clearWindowRuntimeState(windowId);
  }

  void rememberClosed(
    WorkspaceWindowHistoryState state, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    state.insertClosed(
      WorkspaceWindowHistoryEntry(
        workspaceId: workspace.id,
        workspaceName: workspace.name,
        window: window,
        closedAt: DateTime.now(),
      ),
      maxEntries: maxRecentlyClosedWindows,
    );
  }
}

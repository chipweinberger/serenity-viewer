import 'dart:async';

import 'package:serenity_viewer/src/workspace/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/window/session/recently_closed_window_entry.dart';

import 'workspace_controller.dart';

class WorkspaceWindowRuntimeController {
  const WorkspaceWindowRuntimeController({required this.commitInteractionState, required this.windowInteractionState});

  final SerenityWorkspaceCommit commitInteractionState;
  final WindowInteractionState windowInteractionState;

  void flash(String windowId, {required bool mounted}) {
    windowInteractionState.windowFlashTimer?.cancel();
    commitInteractionState(() {
      windowInteractionState.flashedWindowId = windowId;
      windowInteractionState.windowFlashNonce += 1;
    });
    windowInteractionState.windowFlashTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || windowInteractionState.flashedWindowId != windowId) {
        return;
      }
      commitInteractionState(() {
        windowInteractionState.flashedWindowId = null;
      });
    });
  }

  void clear(String windowId) {
    windowInteractionState.previousWindowZOrders.remove(windowId);
  }

  void rememberClosed(
    List<RecentlyClosedWindowEntry> recentlyClosedWindows, {
    required int maxRecentlyClosedWindows,
    required Workspace workspace,
    required Window window,
  }) {
    recentlyClosedWindows.insert(
      0,
      RecentlyClosedWindowEntry(
        workspaceId: workspace.id,
        workspaceName: workspace.name,
        window: window,
        closedAt: DateTime.now(),
      ),
    );

    if (recentlyClosedWindows.length > maxRecentlyClosedWindows) {
      recentlyClosedWindows.removeRange(maxRecentlyClosedWindows, recentlyClosedWindows.length);
    }
  }
}

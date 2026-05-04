import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

import 'workspace_controller.dart';

class WorkspacePlaybackRuntimeState {
  const WorkspacePlaybackRuntimeState({required this.windowInteractionState, required this.commitInteractionState});

  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;

  bool isPaused(String windowId) {
    return windowInteractionState.pausedVideoWindows[windowId] ?? true;
  }

  void toggle(String windowId) {
    commitInteractionState(() {
      windowInteractionState.pausedVideoWindows[windowId] =
          !(windowInteractionState.pausedVideoWindows[windowId] ?? true);
    });
  }

  void stopAll(Environment? environment) {
    if (environment == null) {
      return;
    }

    commitInteractionState(() {
      for (final workspace in environment.workspaces) {
        for (final window in workspace.windows) {
          if (window.asset.type == AssetType.video) {
            windowInteractionState.pausedVideoWindows[window.asset.id] = true;
          }
        }
      }
    });
  }

  void clear(String windowId) {
    windowInteractionState.pausedVideoWindows.remove(windowId);
  }
}

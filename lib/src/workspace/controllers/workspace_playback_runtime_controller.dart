import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class WorkspacePlaybackRuntimeController {
  const WorkspacePlaybackRuntimeController({required this.windowInteractionState});

  final WindowInteractionState windowInteractionState;

  bool isPaused(String windowId) {
    return windowInteractionState.pausedVideoWindows[windowId] ?? true;
  }

  void toggle(String windowId) {
    windowInteractionState.setWindowPaused(windowId, !(windowInteractionState.pausedVideoWindows[windowId] ?? true));
  }

  void stopAll(Environment? environment) {
    if (environment == null) {
      return;
    }

    windowInteractionState.pauseAllVideoWindows(
      environment.workspaces.expand(
        (workspace) =>
            workspace.windows.where((window) => window.asset.type == AssetType.video).map((window) => window.asset.id),
      ),
    );
  }

  void playAll(Environment? environment) {
    if (environment == null) {
      return;
    }

    windowInteractionState.playAllVideoWindows(
      environment.workspaces.expand(
        (workspace) =>
            workspace.windows.where((window) => window.asset.type == AssetType.video).map((window) => window.asset.id),
      ),
    );
  }

  void clear(String windowId) {
    windowInteractionState.removePausedVideoWindow(windowId);
  }
}

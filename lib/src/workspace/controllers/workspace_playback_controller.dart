import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_runtime_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_workspace_controller.dart';

class WorkspacePlaybackController {
  WorkspacePlaybackController({
    required this.windowInteractionState,
    required this.replaceWorkspace,
    required this.environment,
    required this.activeWorkspaceOrNull,
  }) : runtime = WorkspacePlaybackRuntimeController(windowInteractionState: windowInteractionState),
       workspace = WorkspacePlaybackWorkspaceController(replaceWorkspace: replaceWorkspace);

  final WindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final Environment? Function() environment;
  final Workspace? Function() activeWorkspaceOrNull;
  final WorkspacePlaybackRuntimeController runtime;
  final WorkspacePlaybackWorkspaceController workspace;

  void setVideoPosition(String windowId, int positionMs) {
    workspace.setPosition(activeWorkspaceOrNull(), windowId, positionMs);
  }

  void cycleVideoPlaybackSpeed(String windowId) {
    workspace.cycleSpeed(activeWorkspaceOrNull(), windowId);
  }

  bool isVideoWindowPaused(String windowId) {
    return runtime.isPaused(windowId);
  }

  void toggleVideoPlayback(String windowId) {
    if (!workspace.canToggle(activeWorkspaceOrNull(), windowId)) {
      return;
    }

    runtime.toggle(windowId);
  }

  void pauseAllVideos() {
    runtime.stopAll(environment());
  }

  void playAllVideos() {
    runtime.playAll(environment());
  }
}

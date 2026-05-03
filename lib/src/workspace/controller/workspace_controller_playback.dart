import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_playback_runtime.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_playback_workspace.dart';

class WorkspacePlaybackControllerState {
  WorkspacePlaybackControllerState({
    required this.windowInteractionState,
    required this.commitInteractionState,
    required this.replaceWorkspace,
  }) : runtime = WorkspacePlaybackRuntimeState(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       workspace = WorkspacePlaybackWorkspaceState(replaceWorkspace: replaceWorkspace);

  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final WorkspacePlaybackRuntimeState runtime;
  final WorkspacePlaybackWorkspaceState workspace;

  void setVideoPosition(Workspace? workspace, String windowId, int positionMs) {
    this.workspace.setVideoPosition(workspace, windowId, positionMs);
  }

  void cycleVideoPlaybackSpeed(Workspace? workspace, String windowId) {
    this.workspace.cycleVideoPlaybackSpeed(workspace, windowId);
  }

  bool isVideoWindowPaused(String windowId) {
    return runtime.isVideoWindowPaused(windowId);
  }

  void toggleVideoPlayback(Workspace? workspace, String windowId) {
    if (!this.workspace.canToggleVideoPlayback(workspace, windowId)) {
      return;
    }

    runtime.toggleVideoPlayback(windowId);
  }

  void pauseAllVideos(Environment? environment) {
    runtime.pauseAllVideos(environment);
  }

  void clearRuntimeState(String windowId) {
    runtime.clearRuntimeState(windowId);
  }
}

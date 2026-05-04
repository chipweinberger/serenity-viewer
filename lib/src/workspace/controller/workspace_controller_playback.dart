import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
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
}

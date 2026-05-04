import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_playback_runtime.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller_playback_workspace.dart';

class WorkspacePlaybackController {
  WorkspacePlaybackController({
    required this.windowInteractionState,
    required this.commitInteractionState,
    required this.replaceWorkspace,
  }) : runtime = WorkspacePlaybackRuntimeController(
         windowInteractionState: windowInteractionState,
         commitInteractionState: commitInteractionState,
       ),
       workspace = WorkspacePlaybackWorkspaceController(replaceWorkspace: replaceWorkspace);

  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final WorkspacePlaybackRuntimeController runtime;
  final WorkspacePlaybackWorkspaceController workspace;
}

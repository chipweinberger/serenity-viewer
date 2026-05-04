import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_runtime_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_workspace_controller.dart';

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

  final WindowInteractionState windowInteractionState;
  final SerenityWorkspaceCommit commitInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final WorkspacePlaybackRuntimeController runtime;
  final WorkspacePlaybackWorkspaceController workspace;
}

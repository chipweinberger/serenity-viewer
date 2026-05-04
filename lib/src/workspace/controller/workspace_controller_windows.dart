import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';

import 'workspace_controller.dart';
import 'workspace_controller_window_arrangement.dart';
import 'workspace_controller_window_editing.dart';
import 'workspace_controller_window_runtime.dart';

const Size workspaceCollateTargetBox = Size(700, 700);

class WorkspaceWindowControllerState {
  WorkspaceWindowControllerState({
    required this.chromeState,
    required this.commitInteractionState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  }) : arrangement = WorkspaceWindowArrangementState(chromeState: chromeState, replaceWorkspace: replaceWorkspace),
       editing = WorkspaceWindowEditingState(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       runtime = WorkspaceWindowRuntimeState(
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
       );

  final ChromeState chromeState;
  final SerenityWorkspaceCommit commitInteractionState;
  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final WorkspaceWindowArrangementState arrangement;
  final WorkspaceWindowEditingState editing;
  final WorkspaceWindowRuntimeState runtime;
}

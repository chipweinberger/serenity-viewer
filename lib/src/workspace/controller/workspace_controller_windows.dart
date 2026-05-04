import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';

import 'workspace_controller.dart';
import 'workspace_controller_window_arrangement.dart';
import 'workspace_controller_window_editing.dart';
import 'workspace_controller_window_runtime.dart';

const Size workspaceCollateTargetBox = Size(700, 700);

class WorkspaceWindowsController {
  WorkspaceWindowsController({
    required this.chromeState,
    required this.commitInteractionState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  }) : arrangement = WorkspaceWindowArrangementController(chromeState: chromeState, replaceWorkspace: replaceWorkspace),
       editing = WorkspaceWindowEditingController(
         chromeState: chromeState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       runtime = WorkspaceWindowRuntimeController(
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
       );

  final ChromeState chromeState;
  final SerenityWorkspaceCommit commitInteractionState;
  final AssetWindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final WorkspaceWindowArrangementController arrangement;
  final WorkspaceWindowEditingController editing;
  final WorkspaceWindowRuntimeController runtime;
}

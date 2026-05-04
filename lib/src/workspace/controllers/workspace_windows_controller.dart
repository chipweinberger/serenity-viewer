import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/app/app_ui_state.dart';

import 'workspace_controller.dart';
import 'workspace_window_arrangement_controller.dart';
import 'workspace_window_editing_controller.dart';
import 'workspace_window_runtime_controller.dart';

const Size workspaceCollateTargetBox = Size(700, 700);

class WorkspaceWindowsController {
  WorkspaceWindowsController({
    required this.appUiState,
    required this.commitInteractionState,
    required this.windowInteractionState,
    required this.replaceWorkspace,
  }) : arrangement = WorkspaceWindowArrangementController(appUiState: appUiState, replaceWorkspace: replaceWorkspace),
       editing = WorkspaceWindowEditingController(
         appUiState: appUiState,
         windowInteractionState: windowInteractionState,
         replaceWorkspace: replaceWorkspace,
       ),
       runtime = WorkspaceWindowRuntimeController(
         commitInteractionState: commitInteractionState,
         windowInteractionState: windowInteractionState,
       );

  final AppUiState appUiState;
  final SerenityWorkspaceCommit commitInteractionState;
  final WindowInteractionState windowInteractionState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final WorkspaceWindowArrangementController arrangement;
  final WorkspaceWindowEditingController editing;
  final WorkspaceWindowRuntimeController runtime;
}

import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/media/models/media_load_plan.dart';
import 'package:serenity_viewer/src/environment/workspace_state.dart';

@immutable
class WorkspaceCanvasViewModel {
  const WorkspaceCanvasViewModel({
    required this.workspace,
    required this.isExposeMode,
    required this.windows,
    required this.focusedWindowId,
    required this.loadPlan,
    required this.isDropTargetActive,
  });

  final WorkspaceState workspace;
  final bool isExposeMode;
  final List<WorkspaceWindowState> windows;
  final String? focusedWindowId;
  final MediaLoadPlan loadPlan;
  final bool isDropTargetActive;
}

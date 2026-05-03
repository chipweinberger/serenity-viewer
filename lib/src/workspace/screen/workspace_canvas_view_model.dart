import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

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

  final Workspace workspace;
  final bool isExposeMode;
  final List<Window> windows;
  final String? focusedWindowId;
  final MediaLoadPlan loadPlan;
  final bool isDropTargetActive;
}

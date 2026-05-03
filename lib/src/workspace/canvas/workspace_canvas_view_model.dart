import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/workspace/windows/workspace_window_state.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';
import 'package:serenity_viewer/src/workspace/workspace_state.dart';

@immutable
class SerenityWorkspaceCanvasViewModel {
  const SerenityWorkspaceCanvasViewModel({
    required this.workspace,
    required this.isExposeMode,
    required this.windows,
    required this.focusedWindowId,
    required this.loadPlan,
    required this.isDropTargetActive,
  });

  final WorkspaceState workspace;
  final bool isExposeMode;
  final List<AssetWindowState> windows;
  final String? focusedWindowId;
  final SerenityLoadPlan loadPlan;
  final bool isDropTargetActive;
}

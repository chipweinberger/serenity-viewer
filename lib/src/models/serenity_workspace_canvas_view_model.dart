import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/models/asset_window_state.dart';
import 'package:serenity_viewer/src/models/serenity_load_plan.dart';
import 'package:serenity_viewer/src/models/workspace_state.dart';

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

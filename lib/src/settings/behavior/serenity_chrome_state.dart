import 'package:serenity_viewer/src/foundation/serenity_core.dart';

class SerenityChromeState {
  SerenityScreen screen = SerenityScreen.workspace;
  WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform;
  WorkspaceSort workspaceSort = WorkspaceSort.recentlyViewed;
  bool editMode = false;
  bool isDropTargetActive = false;
  String? draggingTabWorkspaceId;
}

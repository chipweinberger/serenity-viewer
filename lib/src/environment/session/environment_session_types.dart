import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

typedef SerenityShowWorkspaceScreen =
    void Function({
      WorkspaceLayoutMode workspaceLayoutMode,
      bool resetEditMode,
      bool clearExposeSelection,
      bool refreshWorkspaceTracking,
    });
typedef SerenityShowLibraryScreen =
    void Function({bool resetEditMode, bool clearExposeSelection, bool refreshWorkspaceTracking});
typedef SerenityQueueWorkspaceRefresh = void Function(String workspaceId, {Duration delay});
typedef SerenityWorkspaceSwitchTargetResolver =
    WorkspaceSwitchTarget Function({
      required List<Workspace> openWorkspaces,
      required String activeWorkspaceId,
      required int direction,
    });

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_api.dart';

class AppNavigationController {
  const AppNavigationController({required this.appUiController});

  final AppUiController appUiController;

  SerenityShowWorkspaceScreen get showWorkspaceScreen {
    return ({
      WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
      bool resetEditMode = true,
      bool clearExposeSelection = true,
      bool refreshWorkspaceTracking = true,
    }) {
      appUiController.showWorkspaceScreen(
        workspaceLayoutMode: workspaceLayoutMode,
        resetEditMode: resetEditMode,
        clearExposeSelection: clearExposeSelection,
        refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
      );
    };
  }

  SerenityShowLibraryScreen get showLibraryScreen {
    return ({bool resetEditMode = true, bool clearExposeSelection = true, bool refreshWorkspaceTracking = true}) {
      appUiController.showLibraryScreen(
        resetEditMode: resetEditMode,
        clearExposeSelection: clearExposeSelection,
        refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
      );
    };
  }
}

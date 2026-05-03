import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';

class AppShellNavigationController {
  const AppShellNavigationController({required this.chromeController});

  final ChromeController chromeController;

  SerenityShowWorkspaceScreen get showWorkspaceScreen {
    return ({
      WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
      bool resetEditMode = true,
      bool clearExposeSelection = true,
      bool refreshWorkspaceTracking = true,
    }) {
      chromeController.showWorkspaceScreen(
        workspaceLayoutMode: workspaceLayoutMode,
        resetEditMode: resetEditMode,
        clearExposeSelection: clearExposeSelection,
        refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
      );
    };
  }

  SerenityShowLibraryScreen get showLibraryScreen {
    return ({bool resetEditMode = true, bool clearExposeSelection = true, bool refreshWorkspaceTracking = true}) {
      chromeController.showLibraryScreen(
        resetEditMode: resetEditMode,
        clearExposeSelection: clearExposeSelection,
        refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
      );
    };
  }
}

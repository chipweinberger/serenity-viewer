import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/layout/workspace_layout.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class WorkspaceViewportFitController {
  const WorkspaceViewportFitController({
    required this.workspaceViewportState,
    required this.replaceWorkspace,
    required this.setWorkspaceViewport,
  });

  final WorkspaceViewportState workspaceViewportState;
  final SerenityWorkspaceReplace replaceWorkspace;
  final SerenityWorkspaceViewportSetter setWorkspaceViewport;

  void toContent(Workspace? workspace) {
    if (workspace == null) {
      return;
    }

    if (workspaceViewportState.viewportSize.width <= 0 ||
        workspaceViewportState.viewportSize.height <= 0 ||
        workspace.windows.isEmpty) {
      setWorkspaceViewport(workspaceId: workspace.id, center: defaultWorkspaceCenter, zoom: 1, queueThumbnail: true);
      return;
    }

    replaceWorkspace(
      WorkspaceLayout.fitWorkspaceViewportToContent(workspace, workspaceViewportState.viewportSize),
      queueThumbnail: true,
    );
  }
}

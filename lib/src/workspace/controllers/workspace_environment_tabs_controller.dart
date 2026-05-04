import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/workspace/mutations/workspace_environment_mutations.dart';

class WorkspaceEnvironmentTabsController {
  const WorkspaceEnvironmentTabsController();

  void toggleOpen(Environment environment, String workspaceId, void Function(Environment) updateEnvironment) {
    updateEnvironment(WorkspaceEnvironmentMutations.toggleWorkspaceOpen(environment, workspaceId));
  }

  void reorderOpen(
    Environment? environment,
    List<Workspace> workspaces, {
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required void Function(Environment) updateEnvironment,
  }) {
    if (environment == null || sourceWorkspaceId == targetWorkspaceId) {
      return;
    }

    updateEnvironment(
      environment.copyWith(
        workspaces: WorkspaceEnvironmentMutations.reorderOpenWorkspaces(
          workspaces,
          sourceWorkspaceId: sourceWorkspaceId,
          targetWorkspaceId: targetWorkspaceId,
        ),
      ),
    );
  }
}

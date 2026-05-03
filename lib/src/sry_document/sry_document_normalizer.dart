import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace_state.dart';

Environment normalizeDecodedEnvironment(Environment environment) {
  final dedupedWorkspaces = <WorkspaceState>[];
  final seenWorkspaceIds = <String>{};

  for (final workspace in environment.workspaces) {
    if (seenWorkspaceIds.add(workspace.id)) {
      dedupedWorkspaces.add(workspace);
    }
  }

  if (dedupedWorkspaces.isEmpty) {
    return environment;
  }

  final hasActiveWorkspace = dedupedWorkspaces.any((workspace) => workspace.id == environment.activeWorkspaceId);
  final nextActiveWorkspaceId = hasActiveWorkspace ? environment.activeWorkspaceId : dedupedWorkspaces.first.id;
  final hasOpenWorkspace = dedupedWorkspaces.any((workspace) => workspace.isOpen);
  final normalizedWorkspaces = dedupedWorkspaces
      .map(
        (workspace) => (!hasOpenWorkspace || workspace.id == nextActiveWorkspaceId) && !workspace.isOpen
            ? workspace.copyWith(isOpen: true)
            : workspace,
      )
      .toList();

  final changed =
      dedupedWorkspaces.length != environment.workspaces.length ||
      nextActiveWorkspaceId != environment.activeWorkspaceId ||
      normalizedWorkspaces.asMap().entries.any((entry) => entry.value.isOpen != dedupedWorkspaces[entry.key].isOpen);

  if (!changed) {
    return environment;
  }

  return Environment(
    workspaces: normalizedWorkspaces,
    activeWorkspaceId: nextActiveWorkspaceId,
    knownFolders: environment.knownFolders,
    folderPopularity: environment.folderPopularity,
    imageLoadLimit: environment.imageLoadLimit,
    shortVideoLoadLimit: environment.shortVideoLoadLimit,
    longVideoLoadLimit: environment.longVideoLoadLimit,
  );
}

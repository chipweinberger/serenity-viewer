import 'package:serenity_viewer/src/sry_document/models/session_state.dart';
import 'package:serenity_viewer/src/sry_document/models/workspace_state.dart';

SessionState normalizeSessionState(SessionState session) {
  final dedupedWorkspaces = <WorkspaceState>[];
  final seenWorkspaceIds = <String>{};

  for (final workspace in session.workspaces) {
    if (seenWorkspaceIds.add(workspace.id)) {
      dedupedWorkspaces.add(workspace);
    }
  }

  if (dedupedWorkspaces.isEmpty) {
    return session;
  }

  final hasActiveWorkspace = dedupedWorkspaces.any((workspace) => workspace.id == session.activeWorkspaceId);
  final nextActiveWorkspaceId = hasActiveWorkspace ? session.activeWorkspaceId : dedupedWorkspaces.first.id;
  final hasOpenWorkspace = dedupedWorkspaces.any((workspace) => workspace.isOpen);
  final normalizedWorkspaces = dedupedWorkspaces
      .map(
        (workspace) => (!hasOpenWorkspace || workspace.id == nextActiveWorkspaceId) && !workspace.isOpen
            ? workspace.copyWith(isOpen: true)
            : workspace,
      )
      .toList();

  final changed =
      dedupedWorkspaces.length != session.workspaces.length ||
      nextActiveWorkspaceId != session.activeWorkspaceId ||
      normalizedWorkspaces.asMap().entries.any((entry) => entry.value.isOpen != dedupedWorkspaces[entry.key].isOpen);

  if (!changed) {
    return session;
  }

  return SessionState(
    workspaces: normalizedWorkspaces,
    activeWorkspaceId: nextActiveWorkspaceId,
    knownFolders: session.knownFolders,
    folderPopularity: session.folderPopularity,
    imageLoadLimit: session.imageLoadLimit,
    shortVideoLoadLimit: session.shortVideoLoadLimit,
    longVideoLoadLimit: session.longVideoLoadLimit,
  );
}

import 'dart:io';

import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

List<Workspace> deriveWorkspaces(AppStateStore state) {
  return state.environmentStoreState.environment?.workspaces ?? const [];
}

List<Workspace> deriveOpenWorkspaces(AppStateStore state) {
  return deriveWorkspaces(state).where((workspace) => workspace.isOpen).toList();
}

Workspace? deriveActiveWorkspaceOrNull(AppStateStore state) {
  final environment = state.environmentStoreState.environment;
  if (environment == null || environment.workspaces.isEmpty) {
    return null;
  }

  final matches = environment.workspaces.where((workspace) => workspace.id == environment.activeWorkspaceId);
  return matches.isNotEmpty ? matches.first : environment.workspaces.first;
}

Workspace deriveActiveWorkspace(AppStateStore state) {
  return deriveActiveWorkspaceOrNull(state) ?? (throw StateError('No active workspace is available.'));
}

String deriveWindowTitle(AppStateStore state) {
  final path = state.environmentStoreState.currentEnvironmentPath;
  final suffix = state.environmentStoreState.hasUnsavedChanges ? ' *' : '';
  if (path == null || path.isEmpty) {
    return 'Serenity$suffix';
  }
  return '${path.split(Platform.pathSeparator).last}$suffix';
}

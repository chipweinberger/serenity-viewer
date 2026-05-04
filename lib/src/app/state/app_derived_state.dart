import 'dart:io';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';

List<Workspace> deriveWorkspaces(EnvironmentStoreState state) {
  return state.environment?.workspaces ?? const [];
}

List<Workspace> deriveOpenWorkspaces(EnvironmentStoreState state) {
  return deriveWorkspaces(state).where((workspace) => workspace.isOpen).toList();
}

Workspace? deriveActiveWorkspaceOrNull(EnvironmentStoreState state) {
  final environment = state.environment;
  if (environment == null || environment.workspaces.isEmpty) {
    return null;
  }

  final matches = environment.workspaces.where((workspace) => workspace.id == environment.activeWorkspaceId);
  return matches.isNotEmpty ? matches.first : environment.workspaces.first;
}

Workspace deriveActiveWorkspace(EnvironmentStoreState state) {
  return deriveActiveWorkspaceOrNull(state) ?? (throw StateError('No active workspace is available.'));
}

String deriveWindowTitle(EnvironmentStoreState state) {
  final path = state.currentEnvironmentPath;
  final suffix = state.hasUnsavedChanges ? ' *' : '';
  if (path == null || path.isEmpty) {
    return 'Serenity$suffix';
  }
  return '${path.split(Platform.pathSeparator).last}$suffix';
}

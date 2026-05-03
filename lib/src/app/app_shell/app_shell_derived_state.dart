import 'dart:io';

import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

class AppShellDerivedState {
  const AppShellDerivedState(this.state);

  final AppShellRuntimeStateServices state;

  List<Workspace> get workspaces => state.persistenceState.environment?.workspaces ?? const [];

  List<Workspace> get openWorkspaces => workspaces.where((workspace) => workspace.isOpen).toList();

  Workspace? get activeWorkspaceOrNull {
    final environment = state.persistenceState.environment;
    if (environment == null || environment.workspaces.isEmpty) {
      return null;
    }

    final matches = environment.workspaces.where((workspace) => workspace.id == environment.activeWorkspaceId);
    return matches.isNotEmpty ? matches.first : environment.workspaces.first;
  }

  Workspace get activeWorkspace {
    return activeWorkspaceOrNull ?? (throw StateError('No active workspace is available.'));
  }

  String get windowTitle {
    final path = state.persistenceState.currentEnvironmentPath;
    final suffix = state.persistenceState.hasUnsavedChanges ? ' *' : '';
    if (path == null || path.isEmpty) {
      return 'Serenity$suffix';
    }
    return '${path.split(Platform.pathSeparator).last}$suffix';
  }
}

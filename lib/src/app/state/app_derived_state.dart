import 'dart:io';

import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

class AppDerivedState {
  const AppDerivedState(this.state);

  final AppRuntimeState state;

  List<Workspace> get workspaces => state.environmentStoreState.environment?.workspaces ?? const [];

  List<Workspace> get openWorkspaces => workspaces.where((workspace) => workspace.isOpen).toList();

  Workspace? get activeWorkspaceOrNull {
    final environment = state.environmentStoreState.environment;
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
    final path = state.environmentStoreState.currentEnvironmentPath;
    final suffix = state.environmentStoreState.hasUnsavedChanges ? ' *' : '';
    if (path == null || path.isEmpty) {
      return 'Serenity$suffix';
    }
    return '${path.split(Platform.pathSeparator).last}$suffix';
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_management.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_navigation.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_shortcuts.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_tracking.dart';
import 'package:serenity_viewer/src/workspace/session/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

typedef SerenityShowWorkspaceScreen =
    void Function({
      WorkspaceLayoutMode workspaceLayoutMode,
      bool resetEditMode,
      bool clearExposeSelection,
      bool refreshWorkspaceTracking,
    });
typedef SerenityShowLibraryScreen =
    void Function({bool resetEditMode, bool clearExposeSelection, bool refreshWorkspaceTracking});
typedef SerenityQueueWorkspaceRefresh = void Function(String workspaceId, {Duration delay});
typedef SerenityWorkspaceSwitchTargetResolver =
    WorkspaceSwitchTarget Function({
      required List<Workspace> openWorkspaces,
      required String activeWorkspaceId,
      required int direction,
    });

class WorkspaceShellController {
  WorkspaceShellController({
    required this.persistenceState,
    required this.chromeState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.workspaceController,
    required this.workspaceLinksController,
    required this.context,
    required this.mounted,
    required this.workspaces,
    required this.openWorkspaces,
    required this.activeWorkspace,
    required this.focusedWindowOrNull,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.showWorkspaceScreen,
    required this.showLibraryScreen,
    required this.toggleExpose,
    required this.showMessage,
    required this.newId,
    required this.workspaceSwitchTarget,
    required this.refreshActiveWorkspaceThumbnail,
    required this.queueWorkspaceRefresh,
    required this.toggleVideoPlayback,
  }) {
    navigation = WorkspaceShellNavigationApi(
      WorkspaceShellNavigationDependencies(
        persistenceState: persistenceState,
        chromeState: chromeState,
        workspaceViewportState: workspaceViewportState,
        workspaceController: workspaceController,
        context: context,
        mounted: mounted,
        openWorkspaces: openWorkspaces,
        activeWorkspace: activeWorkspace,
        updateEnvironment: updateEnvironment,
        replaceWorkspace: replaceWorkspace,
        showWorkspaceScreen: showWorkspaceScreen,
        showLibraryScreen: showLibraryScreen,
        workspaceSwitchTarget: workspaceSwitchTarget,
        refreshActiveWorkspaceThumbnail: refreshActiveWorkspaceThumbnail,
      ),
    );
    management = WorkspaceShellManagementApi(this);
    shortcuts = WorkspaceShellShortcutsApi(
      WorkspaceShellShortcutsDependencies(
        chromeState: chromeState,
        workspaceLinksController: workspaceLinksController,
        focusedWindowOrNull: focusedWindowOrNull,
        showWorkspaceScreen: showWorkspaceScreen,
        toggleExpose: toggleExpose,
        toggleVideoPlayback: toggleVideoPlayback,
        navigation: navigation,
      ),
    );
    tracking = WorkspaceShellTrackingApi(
      WorkspaceShellTrackingDependencies(
        persistenceState: persistenceState,
        chromeState: chromeState,
        workspaceViewTrackingState: workspaceViewTrackingState,
        mounted: mounted,
        activeWorkspace: activeWorkspace,
        updateEnvironment: updateEnvironment,
      ),
    );
  }

  final AppEnvironmentState persistenceState;
  final ChromeState chromeState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final WorkspaceController workspaceController;
  final LinksController workspaceLinksController;
  final BuildContext Function() context;
  final bool Function() mounted;
  final List<Workspace> Function() workspaces;
  final List<Workspace> Function() openWorkspaces;
  final Workspace? Function() activeWorkspace;
  final Window? Function() focusedWindowOrNull;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final SerenityShowLibraryScreen showLibraryScreen;
  final VoidCallback toggleExpose;
  final ValueChanged<String> showMessage;
  final String Function(String prefix) newId;
  final SerenityWorkspaceSwitchTargetResolver workspaceSwitchTarget;
  final Future<void> Function() refreshActiveWorkspaceThumbnail;
  final SerenityQueueWorkspaceRefresh queueWorkspaceRefresh;
  final ValueChanged<String> toggleVideoPlayback;

  late final WorkspaceShellNavigationApi navigation;
  late final WorkspaceShellManagementApi management;
  late final WorkspaceShellShortcutsApi shortcuts;
  late final WorkspaceShellTrackingApi tracking;
}

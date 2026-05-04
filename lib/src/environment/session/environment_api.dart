import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/app_ui_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_view_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_shortcut_controller.dart';
import 'package:serenity_viewer/src/environment/session/workspace_view_tracking_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_management_actions.dart';
import 'package:serenity_viewer/src/environment/session/workspace_view_tracking_state.dart';
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

class EnvironmentApi {
  EnvironmentApi(EnvironmentApiDependencies dependencies)
    : navigation = EnvironmentViewController(
        EnvironmentViewDependencies(
          environmentStoreState: dependencies.environmentStoreState,
          appUiState: dependencies.appUiState,
          workspaceViewportState: dependencies.workspaceViewportState,
          workspaceController: dependencies.workspaceController,
          context: dependencies.context,
          mounted: dependencies.mounted,
          openWorkspaces: dependencies.openWorkspaces,
          activeWorkspace: dependencies.activeWorkspace,
          updateEnvironment: dependencies.updateEnvironment,
          replaceWorkspace: dependencies.replaceWorkspace,
          showWorkspaceScreen: dependencies.showWorkspaceScreen,
          showLibraryScreen: dependencies.showLibraryScreen,
          workspaceSwitchTarget: dependencies.workspaceSwitchTarget,
          refreshActiveWorkspaceThumbnail: dependencies.refreshActiveWorkspaceThumbnail,
        ),
      ) {
    final managementMutations = EnvironmentManagementActions(
      EnvironmentManagementActionDependencies(
        environmentStoreState: dependencies.environmentStoreState,
        appUiState: dependencies.appUiState,
        workspaceController: dependencies.workspaceController,
        workspaces: dependencies.workspaces,
        updateEnvironment: dependencies.updateEnvironment,
        replaceWorkspace: dependencies.replaceWorkspace,
        showWorkspaceScreen: dependencies.showWorkspaceScreen,
        newId: dependencies.newId,
        queueWorkspaceRefresh: dependencies.queueWorkspaceRefresh,
      ),
    );
    management = EnvironmentManagementController(
      EnvironmentManagementDependencies(
        environmentStoreState: dependencies.environmentStoreState,
        workspaceController: dependencies.workspaceController,
        context: dependencies.context,
        mounted: dependencies.mounted,
        workspaces: dependencies.workspaces,
        activeWorkspace: dependencies.activeWorkspace,
        showMessage: dependencies.showMessage,
        navigation: navigation,
        mutations: managementMutations,
      ),
    );
    shortcuts = EnvironmentShortcutController(
      EnvironmentShortcutDependencies(
        appUiState: dependencies.appUiState,
        workspaceLinksController: dependencies.workspaceLinksController,
        focusedWindowOrNull: dependencies.focusedWindowOrNull,
        showWorkspaceScreen: dependencies.showWorkspaceScreen,
        toggleExpose: dependencies.toggleExpose,
        toggleVideoPlayback: dependencies.toggleVideoPlayback,
        navigation: navigation,
      ),
    );
    tracking = WorkspaceViewTrackingController(
      WorkspaceViewTrackingDependencies(
        environmentStoreState: dependencies.environmentStoreState,
        appUiState: dependencies.appUiState,
        workspaceViewTrackingState: dependencies.workspaceViewTrackingState,
        mounted: dependencies.mounted,
        activeWorkspace: dependencies.activeWorkspace,
        updateEnvironment: dependencies.updateEnvironment,
      ),
    );
  }

  final EnvironmentViewController navigation;
  late final EnvironmentManagementController management;
  late final EnvironmentShortcutController shortcuts;
  late final WorkspaceViewTrackingController tracking;
}

class EnvironmentApiDependencies {
  const EnvironmentApiDependencies({
    required this.environmentStoreState,
    required this.appUiState,
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
  });

  final EnvironmentStoreState environmentStoreState;
  final AppUiState appUiState;
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
}

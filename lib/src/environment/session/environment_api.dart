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
  EnvironmentApi({
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
  }) {
    navigation = EnvironmentViewController(
      EnvironmentViewDependencies(
        environmentStoreState: environmentStoreState,
        appUiState: appUiState,
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
    final managementMutations = EnvironmentManagementActions(
      EnvironmentManagementActionDependencies(
        environmentStoreState: environmentStoreState,
        appUiState: appUiState,
        workspaceController: workspaceController,
        workspaces: workspaces,
        updateEnvironment: updateEnvironment,
        replaceWorkspace: replaceWorkspace,
        showWorkspaceScreen: showWorkspaceScreen,
        newId: newId,
        queueWorkspaceRefresh: queueWorkspaceRefresh,
      ),
    );
    management = EnvironmentManagementController(
      EnvironmentManagementDependencies(
        environmentStoreState: environmentStoreState,
        workspaceController: workspaceController,
        context: context,
        mounted: mounted,
        workspaces: workspaces,
        activeWorkspace: activeWorkspace,
        showMessage: showMessage,
        navigation: navigation,
        mutations: managementMutations,
      ),
    );
    shortcuts = EnvironmentShortcutController(
      EnvironmentShortcutDependencies(
        appUiState: appUiState,
        workspaceLinksController: workspaceLinksController,
        focusedWindowOrNull: focusedWindowOrNull,
        showWorkspaceScreen: showWorkspaceScreen,
        toggleExpose: toggleExpose,
        toggleVideoPlayback: toggleVideoPlayback,
        navigation: navigation,
      ),
    );
    tracking = WorkspaceViewTrackingController(
      WorkspaceViewTrackingDependencies(
        environmentStoreState: environmentStoreState,
        appUiState: appUiState,
        workspaceViewTrackingState: workspaceViewTrackingState,
        mounted: mounted,
        activeWorkspace: activeWorkspace,
        updateEnvironment: updateEnvironment,
      ),
    );
  }

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

  late final EnvironmentViewController navigation;
  late final EnvironmentManagementController management;
  late final EnvironmentShortcutController shortcuts;
  late final WorkspaceViewTrackingController tracking;
}

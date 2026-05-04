import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/app_shell_controllers.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_derived_state.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_persistence_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_seed_environment.dart';
import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class AppShellRuntimeConfigBuilder {
  const AppShellRuntimeConfigBuilder({
    required this.dependencies,
    required this.context,
    required this.mounted,
    required this.commitStateChange,
    required this.showMessage,
    required this.isRunningInWidgetTest,
    required this.derivedState,
    required this.foundation,
    required this.controller,
    required this.persistence,
    required this.newId,
    required this.colorFromDigest,
  });

  final ShellDependencies dependencies;
  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final ValueChanged<String> showMessage;
  final bool isRunningInWidgetTest;
  final AppShellDerivedState Function() derivedState;
  final AppShellRuntimeFoundationServices Function() foundation;
  final AppShellController Function() controller;
  final AppShellPersistenceController Function() persistence;
  final String Function(String prefix) newId;
  final int Function(String value) colorFromDigest;

  AppShellRuntimeConfig build() {
    return AppShellRuntimeConfig(
      isRunningInWidgetTest: isRunningInWidgetTest,
      dependencies: dependencies,
      shell: AppShellRuntimeShellConfig(
        windowTitle: () => derivedState().windowTitle,
        context: context,
        mounted: mounted,
        commitStateChange: commitStateChange,
        showMessage: showMessage,
      ),
      environment: AppShellRuntimeEnvironmentConfig(
        seedEnvironment: buildSeedEnvironment,
        updateEnvironment: (environment) => foundation().environmentController.updateEnvironment(environment),
        replaceWorkspace: (workspace, {queueThumbnail = true}) =>
            foundation().environmentController.replaceWorkspace(workspace, queueThumbnail: queueThumbnail),
        saveEnvironment: () => persistence().saveEnvironment(),
      ),
      workspace: AppShellRuntimeWorkspaceConfig(
        newId: newId,
        colorFromDigest: colorFromDigest,
        activeWorkspace: () => derivedState().activeWorkspaceOrNull,
        workspaces: () => derivedState().workspaces,
        openWorkspaces: () => derivedState().openWorkspaces,
        focusedWindowOrNull: () => controller().windowHistory.focusedWindowOrNull(),
        setWorkspaceViewport:
            ({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) =>
                controller().geometry.setWorkspaceViewport(
                  workspaceId: workspaceId,
                  center: center,
                  zoom: zoom,
                  queueThumbnail: queueThumbnail,
                ),
        showWorkspaceScreen:
            ({
              WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
              bool resetEditMode = true,
              bool clearExposeSelection = true,
              bool refreshWorkspaceTracking = true,
            }) => foundation().chromeController.showWorkspaceScreen(
              workspaceLayoutMode: workspaceLayoutMode,
              resetEditMode: resetEditMode,
              clearExposeSelection: clearExposeSelection,
              refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
            ),
        showLibraryScreen:
            ({bool resetEditMode = true, bool clearExposeSelection = true, bool refreshWorkspaceTracking = true}) =>
                foundation().chromeController.showLibraryScreen(
                  resetEditMode: resetEditMode,
                  clearExposeSelection: clearExposeSelection,
                  refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
                ),
        toggleExpose: () => foundation().chromeController.toggleExpose(),
        toggleVideoPlayback: (windowId) => controller().window.toggleVideoPlayback(windowId),
      ),
    );
  }
}

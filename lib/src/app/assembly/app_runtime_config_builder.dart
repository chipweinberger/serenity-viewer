import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_actions.dart';
import 'package:serenity_viewer/src/app/app_derived_state.dart';
import 'package:serenity_viewer/src/app/app_persistence_controller.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/app_dependencies.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class AppRuntimeConfigBuilder {
  const AppRuntimeConfigBuilder({
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

  final AppDependencies dependencies;
  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final ValueChanged<String> showMessage;
  final bool isRunningInWidgetTest;
  final AppDerivedState Function() derivedState;
  final AppFoundation Function() foundation;
  final AppActions Function() controller;
  final AppPersistenceController Function() persistence;
  final String Function(String prefix) newId;
  final int Function(String value) colorFromDigest;

  AppRuntimeConfig build() {
    return AppRuntimeConfig(
      isRunningInWidgetTest: isRunningInWidgetTest,
      dependencies: dependencies,
      shell: AppConfig(
        windowTitle: () => derivedState().windowTitle,
        context: context,
        mounted: mounted,
        commitStateChange: commitStateChange,
        showMessage: showMessage,
      ),
      environment: EnvironmentConfig(
        seedEnvironment: buildSeedEnvironment,
        updateEnvironment: (environment) => foundation().environmentStore.updateEnvironment(environment),
        replaceWorkspace: (workspace, {queueThumbnail = true}) =>
            foundation().environmentStore.replaceWorkspace(workspace, queueThumbnail: queueThumbnail),
        saveEnvironment: () => persistence().saveEnvironment(),
      ),
      workspace: WorkspaceConfig(
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
            }) => foundation().appUiController.showWorkspaceScreen(
              workspaceLayoutMode: workspaceLayoutMode,
              resetEditMode: resetEditMode,
              clearExposeSelection: clearExposeSelection,
              refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
            ),
        showLibraryScreen:
            ({bool resetEditMode = true, bool clearExposeSelection = true, bool refreshWorkspaceTracking = true}) =>
                foundation().appUiController.showLibraryScreen(
                  resetEditMode: resetEditMode,
                  clearExposeSelection: clearExposeSelection,
                  refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
                ),
        toggleExpose: () => foundation().appUiController.toggleExpose(),
        toggleVideoPlayback: (windowId) => controller().window.toggleVideoPlayback(windowId),
      ),
    );
  }
}

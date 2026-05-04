import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/assembly/app_runtime_config.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime_services.dart';
import 'package:serenity_viewer/src/app/app_view_state.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
import 'package:serenity_viewer/src/app/app_owned_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class AppRuntimeConfigBuilder {
  const AppRuntimeConfigBuilder({
    required this.ownedState,
    required this.context,
    required this.mounted,
    required this.commitStateChange,
    required this.showMessage,
    required this.isRunningInWidgetTest,
    required this.viewState,
    required this.foundation,
    required this.workspace,
    required this.documentPersistence,
  });

  final AppOwnedState ownedState;
  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final ValueChanged<String> showMessage;
  final bool isRunningInWidgetTest;
  final AppViewState Function() viewState;
  final AppFoundation Function() foundation;
  final AppWorkspaceServices Function() workspace;
  final DocumentPersistenceController Function() documentPersistence;

  AppRuntimeConfig build() {
    return AppRuntimeConfig(
      isRunningInWidgetTest: isRunningInWidgetTest,
      ownedState: ownedState,
      shell: AppConfig(
        windowTitle: () => viewState().windowTitle,
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
        saveEnvironment: () => documentPersistence().saveEnvironment(),
      ),
      workspace: WorkspaceConfig(
        newId: newSerenityId,
        colorFromDigest: assetColorValueFromDigest,
        activeWorkspace: () => viewState().activeWorkspaceOrNull,
        workspaces: () => viewState().workspaces,
        openWorkspaces: () => viewState().openWorkspaces,
        focusedWindowOrNull: () => workspace().workspaceWindowController.focusedWindowOrNull(),
        setWorkspaceViewport:
            ({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) =>
                workspace().workspaceViewportSessionController.setWorkspaceViewport(
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
        toggleVideoPlayback: (windowId) => workspace().workspaceWindowController.toggleVideoPlayback(windowId),
      ),
    );
  }
}

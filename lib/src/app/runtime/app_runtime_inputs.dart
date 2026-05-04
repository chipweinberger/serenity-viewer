import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';

class AppRuntimeInputs {
  const AppRuntimeInputs({
    required this.isRunningInWidgetTest,
    required this.stateStore,
    required this.uiHandles,
    required this.windowTitle,
    required this.context,
    required this.mounted,
    required this.showMessage,
    required this.seedEnvironment,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.saveEnvironment,
    required this.newId,
    required this.colorFromDigest,
    required this.activeWorkspace,
    required this.workspaces,
    required this.openWorkspaces,
    required this.focusedWindowOrNull,
    required this.setWorkspaceViewport,
    required this.showWorkspaceScreen,
    required this.showLibraryScreen,
    required this.toggleExpose,
    required this.toggleVideoPlayback,
  });

  final bool isRunningInWidgetTest;
  final AppStateStore stateStore;
  final AppUiHandles uiHandles;
  final String Function() windowTitle;
  final BuildContext Function() context;
  final bool Function() mounted;
  final ValueChanged<String> showMessage;
  final Environment Function() seedEnvironment;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final Future<void> Function() saveEnvironment;
  final String Function(String prefix) newId;
  final int Function(String value) colorFromDigest;
  final Workspace? Function() activeWorkspace;
  final List<Workspace> Function() workspaces;
  final List<Workspace> Function() openWorkspaces;
  final Window? Function() focusedWindowOrNull;
  final void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
  setWorkspaceViewport;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final SerenityShowLibraryScreen showLibraryScreen;
  final VoidCallback toggleExpose;
  final ValueChanged<String> toggleVideoPlayback;
}

String Function() _buildRuntimeWindowTitle({
  required AppStateStore stateStore,
}) {
  return () => deriveWindowTitle(stateStore);
}

Environment Function() _buildRuntimeSeedEnvironment() {
  return buildSeedEnvironment;
}

ValueChanged<Environment> _buildRuntimeUpdateEnvironment({
  required EnvironmentStore Function() environmentStore,
}) {
  return (environment) => environmentStore().updateEnvironment(environment);
}

void Function(Workspace workspace, {bool queueThumbnail}) _buildRuntimeReplaceWorkspace({
  required EnvironmentStore Function() environmentStore,
}) {
  return (workspace, {queueThumbnail = true}) =>
      environmentStore().replaceWorkspace(workspace, queueThumbnail: queueThumbnail);
}

Future<void> Function() _buildRuntimeSaveEnvironment({
  required DocumentPersistenceController Function() documentPersistence,
}) {
  return () => documentPersistence().saveEnvironment();
}

AppRuntimeInputs buildAppRuntimeInputs({
  required AppStateStore stateStore,
  required AppUiHandles uiHandles,
  required BuildContext Function() context,
  required bool Function() mounted,
  required ValueChanged<String> showMessage,
  required bool isRunningInWidgetTest,
  required EnvironmentStore Function() environmentStore,
  required AppUiController Function() appUiController,
  required WorkspaceWindowController Function() workspaceWindowController,
  required WorkspaceViewportSessionController Function() workspaceViewportSessionController,
  required DocumentPersistenceController Function() documentPersistence,
}) {
  return AppRuntimeInputs(
    isRunningInWidgetTest: isRunningInWidgetTest,
    stateStore: stateStore,
    uiHandles: uiHandles,
    windowTitle: _buildRuntimeWindowTitle(stateStore: stateStore),
    context: context,
    mounted: mounted,
    showMessage: showMessage,
    seedEnvironment: _buildRuntimeSeedEnvironment(),
    updateEnvironment: _buildRuntimeUpdateEnvironment(environmentStore: environmentStore),
    replaceWorkspace: _buildRuntimeReplaceWorkspace(environmentStore: environmentStore),
    saveEnvironment: _buildRuntimeSaveEnvironment(documentPersistence: documentPersistence),
    newId: newSerenityId,
    colorFromDigest: assetColorValueFromDigest,
    activeWorkspace: () => deriveActiveWorkspaceOrNull(stateStore),
    workspaces: () => deriveWorkspaces(stateStore),
    openWorkspaces: () => deriveOpenWorkspaces(stateStore),
    focusedWindowOrNull: () => workspaceWindowController().focusedWindowOrNull(),
    setWorkspaceViewport:
        ({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) =>
            workspaceViewportSessionController().setWorkspaceViewport(
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
        }) => appUiController().showWorkspaceScreen(
          workspaceLayoutMode: workspaceLayoutMode,
          resetEditMode: resetEditMode,
          clearExposeSelection: clearExposeSelection,
          refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
        ),
    showLibraryScreen:
        ({bool resetEditMode = true, bool clearExposeSelection = true, bool refreshWorkspaceTracking = true}) =>
            appUiController().showLibraryScreen(
              resetEditMode: resetEditMode,
              clearExposeSelection: clearExposeSelection,
              refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
            ),
    toggleExpose: () => appUiController().toggleExpose(),
    toggleVideoPlayback: (windowId) => workspaceWindowController().toggleVideoPlayback(windowId),
  );
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';

class AppRuntimeInputs {
  const AppRuntimeInputs({
    required this.isRunningInWidgetTest,
    required this.stateStore,
    required this.uiHandles,
    required this.app,
    required this.environment,
    required this.workspace,
  });

  final bool isRunningInWidgetTest;
  final AppStateStore stateStore;
  final AppUiHandles uiHandles;
  final AppRuntimeAppInputs app;
  final AppRuntimeEnvironmentInputs environment;
  final AppRuntimeWorkspaceInputs workspace;
}

class AppRuntimeAppInputs {
  const AppRuntimeAppInputs({
    required this.windowTitle,
    required this.context,
    required this.mounted,
    required this.commitStateChange,
    required this.showMessage,
  });

  final String Function() windowTitle;
  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final ValueChanged<String> showMessage;
}

class AppRuntimeEnvironmentInputs {
  const AppRuntimeEnvironmentInputs({
    required this.seedEnvironment,
    required this.updateEnvironment,
    required this.replaceWorkspace,
    required this.saveEnvironment,
  });

  final Environment Function() seedEnvironment;
  final ValueChanged<Environment> updateEnvironment;
  final void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace;
  final Future<void> Function() saveEnvironment;
}

class AppRuntimeWorkspaceInputs {
  const AppRuntimeWorkspaceInputs({
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

class AppRuntimeInputBuilder {
  const AppRuntimeInputBuilder({
    required this.stateStore,
    required this.uiHandles,
    required this.context,
    required this.mounted,
    required this.commitStateChange,
    required this.showMessage,
    required this.isRunningInWidgetTest,
    required this.derivedState,
    required this.foundation,
    required this.workspace,
    required this.documentPersistence,
  });

  final AppStateStore stateStore;
  final AppUiHandles uiHandles;
  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final ValueChanged<String> showMessage;
  final bool isRunningInWidgetTest;
  final AppDerivedState Function() derivedState;
  final AppFoundation Function() foundation;
  final AppWorkspaceServices Function() workspace;
  final DocumentPersistenceController Function() documentPersistence;

  AppRuntimeAppInputs _buildAppInputs() {
    return AppRuntimeAppInputs(
      windowTitle: () => derivedState().windowTitle,
      context: context,
      mounted: mounted,
      commitStateChange: commitStateChange,
      showMessage: showMessage,
    );
  }

  AppRuntimeEnvironmentInputs _buildEnvironmentInputs() {
    return AppRuntimeEnvironmentInputs(
      seedEnvironment: buildSeedEnvironment,
      updateEnvironment: (environment) => foundation().environmentStore.updateEnvironment(environment),
      replaceWorkspace: (workspace, {queueThumbnail = true}) =>
          foundation().environmentStore.replaceWorkspace(workspace, queueThumbnail: queueThumbnail),
      saveEnvironment: () => documentPersistence().saveEnvironment(),
    );
  }

  AppRuntimeWorkspaceInputs _buildWorkspaceInputs() {
    return AppRuntimeWorkspaceInputs(
      newId: newSerenityId,
      colorFromDigest: assetColorValueFromDigest,
      activeWorkspace: () => derivedState().activeWorkspaceOrNull,
      workspaces: () => derivedState().workspaces,
      openWorkspaces: () => derivedState().openWorkspaces,
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
    );
  }

  AppRuntimeInputs build() {
    return AppRuntimeInputs(
      isRunningInWidgetTest: isRunningInWidgetTest,
      stateStore: stateStore,
      uiHandles: uiHandles,
      app: _buildAppInputs(),
      environment: _buildEnvironmentInputs(),
      workspace: _buildWorkspaceInputs(),
    );
  }
}

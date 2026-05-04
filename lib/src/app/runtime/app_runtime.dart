import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/factories/app_document_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_foundation_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';

export 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
export 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';

class AppRuntime {
  AppRuntime.assembled({
    required this.stateStore,
    required this.state,
    required this.foundation,
    required this.documents,
    required this.workspace,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final AppStateStore stateStore;
  final AppRuntimeState state;
  final AppFoundation foundation;
  final AppDocument documents;
  final AppWorkspaceServices workspace;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  static AppRuntime create(AppRuntimeInputs inputs) {
    final stateStore = inputs.stateStore;
    final environmentStoreState = stateStore.environmentStoreState;
    late final AppFoundation foundation;
    late final AppWorkspaceServices workspace;

    foundation = createAppFoundation(
      inputs: inputs,
      refreshWorkspaceTracking: () async => workspace.workspaceViewTrackingController.refresh(),
      markWorkspaceThumbnailDirty: (workspaceId) => workspace.thumbnailController.markWorkspaceDirty(workspaceId),
      syncWindowTitle: () async => foundation.platformBridge.syncWindowTitle(),
    );
    workspace = createAppWorkspaceServices(inputs: inputs, foundation: foundation);
    final documents = createAppDocument(inputs: inputs, foundation: foundation, workspace: workspace);
    final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (environmentStoreState.hasUnsavedChanges) {
        unawaited(inputs.environment.saveEnvironment());
      }
    });
    final appLifecycleListener = AppLifecycleListener(
      onStateChange: workspace.workspaceViewTrackingController.handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await inputs.environment.saveEnvironment();
        return ui.AppExitResponse.exit;
      },
    );

    return AppRuntime.assembled(
      stateStore: stateStore,
      state: AppRuntimeState(
        uiHandles: inputs.uiHandles,
        environmentStoreState: stateStore.environmentStoreState,
        appUiState: stateStore.appUiState,
        windowInteractionState: stateStore.windowInteractionState,
        workspaceViewTrackingState: stateStore.workspaceViewTrackingState,
        workspaceViewportState: stateStore.workspaceViewportState,
        thumbnailRefreshState: stateStore.thumbnailRefreshState,
        workspaceWindowHistoryState: stateStore.workspaceWindowHistoryState,
      ),
      foundation: foundation,
      documents: documents,
      workspace: workspace,
      autosaveTimer: autosaveTimer,
      appLifecycleListener: appLifecycleListener,
    );
  }

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspace.workspaceViewTrackingController.cancel();
    stateStore.workspaceViewTrackingState.dispose();
    stateStore.windowInteractionState.dispose();
    workspace.thumbnailController.dispose();
    foundation.sharedVideoControllerPool.dispose();
    state.uiHandles.dispose();
  }
}

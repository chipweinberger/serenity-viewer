import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/assembly/app_document_factory.dart';
import 'package:serenity_viewer/src/app/assembly/app_foundation_factory.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime_config.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime_bridge.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime_services.dart';
import 'package:serenity_viewer/src/app/assembly/app_workspace_factory.dart';

export 'package:serenity_viewer/src/app/assembly/app_runtime_config.dart';
export 'package:serenity_viewer/src/app/assembly/app_runtime_services.dart';

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

  static AppRuntime create(AppRuntimeConfig config) {
    final stateStore = config.stateStore;
    final environmentStoreState = stateStore.environmentStoreState;
    final bridge = AppRuntimeBridge();

    final foundation = AppFoundationFactory(config).create(
      refreshWorkspaceTracking: bridge.refreshWorkspaceTracking,
      markWorkspaceThumbnailDirty: bridge.markWorkspaceThumbnailDirty,
      syncWindowTitle: bridge.syncWindowTitle,
    );
    bridge.bindFoundation(foundation);
    final workspace = AppWorkspaceFactory(config).create(foundation: foundation);
    bridge.bindWorkspace(workspace);
    final documentCoordinator = AppDocumentFactory(config).create(foundation: foundation, workspace: workspace);
    final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (environmentStoreState.hasUnsavedChanges) {
        unawaited(config.environment.saveEnvironment());
      }
    });
    final appLifecycleListener = AppLifecycleListener(
      onStateChange: workspace.workspaceViewTrackingController.handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await config.environment.saveEnvironment();
        return ui.AppExitResponse.exit;
      },
    );

    return AppRuntime.assembled(
      stateStore: stateStore,
      state: AppRuntimeState(
        uiHandles: config.uiHandles,
        environmentStoreState: stateStore.environmentStoreState,
        appUiState: stateStore.appUiState,
        windowInteractionState: stateStore.windowInteractionState,
        workspaceViewTrackingState: stateStore.workspaceViewTrackingState,
        workspaceViewportState: stateStore.workspaceViewportState,
        thumbnailRefreshState: stateStore.thumbnailRefreshState,
        workspaceWindowHistoryState: stateStore.workspaceWindowHistoryState,
      ),
      foundation: foundation,
      documents: AppDocument(documentCoordinator: documentCoordinator),
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

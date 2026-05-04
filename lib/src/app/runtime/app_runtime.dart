import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/factories/app_document_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_foundation_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';

export 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
export 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';

class AppRuntime {
  AppRuntime.assembled({
    required this.foundation,
    required this.documentCoordinator,
    required this.workspace,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final AppFoundation foundation;
  final DocumentCoordinator documentCoordinator;
  final AppWorkspaceServices workspace;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  AppUiController get appUiController => foundation.appUiController;
  PlatformBridge get platformBridge => foundation.platformBridge;
  SharedVideoControllerPool get sharedVideoControllerPool => foundation.sharedVideoControllerPool;
  EnvironmentStore get environmentStore => foundation.environmentStore;
  EnvironmentBookmarkSynchronizer get environmentBookmarkSynchronizer =>
      foundation.environmentBookmarkSynchronizer;
  ThumbnailController get thumbnailController => workspace.thumbnailController;
  WorkspaceAssetPickerController get workspaceAssetPickerController => workspace.workspaceAssetPickerController;
  WorkspaceCollateController get workspaceCollateController => workspace.workspaceCollateController;
  WorkspaceVideoConversionController get workspaceVideoConversionController =>
      workspace.workspaceVideoConversionController;
  WorkspaceMediaImportController get workspaceMediaImportController => workspace.workspaceMediaImportController;
  WorkspaceLinksController get workspaceLinksController => workspace.workspaceLinksController;
  WorkspaceLinksLauncher get workspaceLinksLauncher => workspace.workspaceLinksLauncher;
  WorkspaceLinksPrompts get workspaceLinksPrompts => workspace.workspaceLinksPrompts;
  WorkspaceController get workspaceController => workspace.workspaceController;
  WorkspaceWindowController get workspaceWindowController => workspace.workspaceWindowController;
  WorkspaceWindowHistoryController get workspaceWindowHistoryController =>
      workspace.workspaceWindowHistoryController;
  WorkspaceViewportSessionController get workspaceViewportSessionController =>
      workspace.workspaceViewportSessionController;
  EnvironmentController get environmentController => workspace.environmentController;
  WorkspaceExposeLayoutController get workspaceExposeLayoutController => workspace.workspaceExposeLayoutController;
  WorkspaceShortcutController get workspaceShortcutController => workspace.workspaceShortcutController;

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
    workspace = createAppWorkspaceServices(
      inputs: inputs,
      platformBridge: foundation.platformBridge,
      environmentStore: foundation.environmentStore,
      mediaInspector: foundation.mediaInspector,
      appUiController: foundation.appUiController,
    );
    final documentCoordinator = createAppDocumentCoordinator(
      inputs: inputs,
      environmentStore: foundation.environmentStore,
      refreshActiveWorkspaceThumbnailIfNeeded: () async => workspace.thumbnailController.refreshActiveWorkspaceIfNeeded(),
      storeLastEnvironmentPath: foundation.platformBridge.storeLastEnvironmentPath,
      syncWindowTitle: foundation.platformBridge.syncWindowTitle,
      resolveFileBookmark: foundation.platformBridge.resolveFileBookmark,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      thumbnailDirectory: foundation.platformBridge.thumbnailDirectory,
    );
    final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (environmentStoreState.hasUnsavedChanges) {
        unawaited(inputs.saveEnvironment());
      }
    });
    final appLifecycleListener = AppLifecycleListener(
      onStateChange: workspace.workspaceViewTrackingController.handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await inputs.saveEnvironment();
        return ui.AppExitResponse.exit;
      },
    );

    return AppRuntime.assembled(
      foundation: foundation,
      documentCoordinator: documentCoordinator,
      workspace: workspace,
      autosaveTimer: autosaveTimer,
      appLifecycleListener: appLifecycleListener,
    );
  }

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspace.workspaceViewTrackingController.cancel();
    workspace.thumbnailController.dispose();
    foundation.sharedVideoControllerPool.dispose();
  }
}

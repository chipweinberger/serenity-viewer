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

export 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';

class AppRuntime {
  AppRuntime.assembled({
    required AppFoundation foundation,
    required this.documentCoordinator,
    required AppWorkspaceServices workspace,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  }) : _foundation = foundation,
       _workspace = workspace;

  final AppFoundation _foundation;
  final DocumentCoordinator documentCoordinator;
  final AppWorkspaceServices _workspace;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  AppUiController get appUiController => _foundation.appUiController;
  PlatformBridge get platformBridge => _foundation.platformBridge;
  SharedVideoControllerPool get sharedVideoControllerPool => _foundation.sharedVideoControllerPool;
  EnvironmentStore get environmentStore => _foundation.environmentStore;
  EnvironmentBookmarkSynchronizer get environmentBookmarkSynchronizer =>
      _foundation.environmentBookmarkSynchronizer;
  ThumbnailController get thumbnailController => _workspace.thumbnailController;
  WorkspaceAssetPickerController get workspaceAssetPickerController => _workspace.workspaceAssetPickerController;
  WorkspaceCollateController get workspaceCollateController => _workspace.workspaceCollateController;
  WorkspaceVideoConversionController get workspaceVideoConversionController =>
      _workspace.workspaceVideoConversionController;
  WorkspaceMediaImportController get workspaceMediaImportController => _workspace.workspaceMediaImportController;
  WorkspaceLinksController get workspaceLinksController => _workspace.workspaceLinksController;
  WorkspaceLinksLauncher get workspaceLinksLauncher => _workspace.workspaceLinksLauncher;
  WorkspaceLinksPrompts get workspaceLinksPrompts => _workspace.workspaceLinksPrompts;
  WorkspaceController get workspaceController => _workspace.workspaceController;
  WorkspaceWindowController get workspaceWindowController => _workspace.workspaceWindowController;
  WorkspaceWindowHistoryController get workspaceWindowHistoryController =>
      _workspace.workspaceWindowHistoryController;
  WorkspaceViewportSessionController get workspaceViewportSessionController =>
      _workspace.workspaceViewportSessionController;
  EnvironmentController get environmentController => _workspace.environmentController;
  WorkspaceExposeLayoutController get workspaceExposeLayoutController => _workspace.workspaceExposeLayoutController;
  WorkspaceShortcutController get workspaceShortcutController => _workspace.workspaceShortcutController;

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
    _workspace.workspaceViewTrackingController.cancel();
    _workspace.thumbnailController.dispose();
    _foundation.sharedVideoControllerPool.dispose();
  }
}

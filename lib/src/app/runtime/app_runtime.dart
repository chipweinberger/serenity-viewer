import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/factories/app_document_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_foundation_factory.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/media_inspector.dart';
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
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_controller.dart';

export 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';

class AppRuntime {
  AppRuntime.assembled({
    required this.appUiController,
    required this.platformBridge,
    required this.sharedVideoControllerPool,
    required this.environmentStore,
    required this.environmentBookmarkSynchronizer,
    required this.documentCoordinator,
    required this.thumbnailController,
    required this.workspaceAssetPickerController,
    required this.workspaceCollateController,
    required this.workspaceVideoConversionController,
    required this.workspaceMediaImportController,
    required this.workspaceLinksController,
    required this.workspaceLinksLauncher,
    required this.workspaceLinksPrompts,
    required this.workspaceController,
    required this.workspaceWindowController,
    required this.workspaceWindowHistoryController,
    required this.workspaceViewportSessionController,
    required this.environmentController,
    required this.workspaceExposeLayoutController,
    required this.workspaceShortcutController,
    required this.workspaceViewTrackingController,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final AppUiController appUiController;
  final PlatformBridge platformBridge;
  final SharedVideoControllerPool sharedVideoControllerPool;
  final EnvironmentStore environmentStore;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final DocumentCoordinator documentCoordinator;
  final ThumbnailController thumbnailController;
  final WorkspaceAssetPickerController workspaceAssetPickerController;
  final WorkspaceCollateController workspaceCollateController;
  final WorkspaceVideoConversionController workspaceVideoConversionController;
  final WorkspaceMediaImportController workspaceMediaImportController;
  final WorkspaceLinksController workspaceLinksController;
  final WorkspaceLinksLauncher workspaceLinksLauncher;
  final WorkspaceLinksPrompts workspaceLinksPrompts;
  final WorkspaceController workspaceController;
  final WorkspaceWindowController workspaceWindowController;
  final WorkspaceWindowHistoryController workspaceWindowHistoryController;
  final WorkspaceViewportSessionController workspaceViewportSessionController;
  final EnvironmentController environmentController;
  final WorkspaceExposeLayoutController workspaceExposeLayoutController;
  final WorkspaceShortcutController workspaceShortcutController;
  final WorkspaceViewTrackingController workspaceViewTrackingController;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  static AppRuntime create(AppRuntimeInputs inputs) {
    final stateStore = inputs.stateStore;
    final environmentStoreState = stateStore.environmentStoreState;
    late final ({
      AppUiController appUiController,
      MediaInspector mediaInspector,
      PlatformBridge platformBridge,
      SharedVideoControllerPool sharedVideoControllerPool,
      EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer,
      EnvironmentStore environmentStore,
    }) foundation;
    late final ({
      ThumbnailController thumbnailController,
      WorkspaceAssetPickerController workspaceAssetPickerController,
      WorkspaceCollateController workspaceCollateController,
      WorkspaceVideoConversionController workspaceVideoConversionController,
      WorkspaceMediaImportController workspaceMediaImportController,
      WorkspaceLinksController workspaceLinksController,
      WorkspaceLinksLauncher workspaceLinksLauncher,
      WorkspaceLinksPrompts workspaceLinksPrompts,
      WorkspaceController workspaceController,
      WorkspaceWindowController workspaceWindowController,
      WorkspaceWindowHistoryController workspaceWindowHistoryController,
      WorkspaceViewportSessionController workspaceViewportSessionController,
      EnvironmentController environmentController,
      WorkspaceExposeLayoutController workspaceExposeLayoutController,
      WorkspaceShortcutController workspaceShortcutController,
      WorkspaceViewTrackingController workspaceViewTrackingController,
    }) workspace;

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
      appUiController: foundation.appUiController,
      platformBridge: foundation.platformBridge,
      sharedVideoControllerPool: foundation.sharedVideoControllerPool,
      environmentStore: foundation.environmentStore,
      environmentBookmarkSynchronizer: foundation.environmentBookmarkSynchronizer,
      documentCoordinator: documentCoordinator,
      thumbnailController: workspace.thumbnailController,
      workspaceAssetPickerController: workspace.workspaceAssetPickerController,
      workspaceCollateController: workspace.workspaceCollateController,
      workspaceVideoConversionController: workspace.workspaceVideoConversionController,
      workspaceMediaImportController: workspace.workspaceMediaImportController,
      workspaceLinksController: workspace.workspaceLinksController,
      workspaceLinksLauncher: workspace.workspaceLinksLauncher,
      workspaceLinksPrompts: workspace.workspaceLinksPrompts,
      workspaceController: workspace.workspaceController,
      workspaceWindowController: workspace.workspaceWindowController,
      workspaceWindowHistoryController: workspace.workspaceWindowHistoryController,
      workspaceViewportSessionController: workspace.workspaceViewportSessionController,
      environmentController: workspace.environmentController,
      workspaceExposeLayoutController: workspace.workspaceExposeLayoutController,
      workspaceShortcutController: workspace.workspaceShortcutController,
      workspaceViewTrackingController: workspace.workspaceViewTrackingController,
      autosaveTimer: autosaveTimer,
      appLifecycleListener: appLifecycleListener,
    );
  }

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspaceViewTrackingController.cancel();
    thumbnailController.dispose();
    sharedVideoControllerPool.dispose();
  }
}

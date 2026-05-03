import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime_document_factory.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime_foundation_factory.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime_workspace_factory.dart';

class AppShellRuntimeFactory {
  const AppShellRuntimeFactory(this.config);

  final AppShellRuntimeConfig config;

  AppShellRuntime create() {
    final dependencies = config.dependencies;
    final persistenceState = dependencies.persistenceState;
    late AppShellRuntimeWorkspace workspace;
    late AppShellRuntimeFoundation foundation;

    foundation = AppShellRuntimeFoundationFactory(config).create(
      refreshWorkspaceTracking: () async => workspace.workspaceShellController.tracking.refresh(),
      markWorkspaceThumbnailDirty: (workspaceId) => workspace.thumbnailController.markWorkspaceDirty(workspaceId),
      syncWindowTitle: () => foundation.appShellPlatformBridge.syncWindowTitle(),
    );
    workspace = AppShellRuntimeWorkspaceFactory(config).create(
      foundation: foundation,
      refreshWorkspaceTracking: () async => workspace.workspaceShellController.tracking.refresh(),
    );
    final sryDocumentCoordinator = AppShellRuntimeDocumentFactory(
      config,
    ).create(foundation: foundation, workspace: workspace);
    final autosaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (persistenceState.hasUnsavedChanges) {
        unawaited(config.saveEnvironment());
      }
    });
    final appLifecycleListener = AppLifecycleListener(
      onStateChange: workspace.workspaceShellController.tracking.handleAppLifecycleStateChanged,
      onExitRequested: () async {
        await config.saveEnvironment();
        return ui.AppExitResponse.exit;
      },
    );

    return AppShellRuntime.assembled(
      dependencies: dependencies,
      chromeController: foundation.chromeController,
      sryDocumentCoordinator: sryDocumentCoordinator,
      mediaBridge: foundation.mediaBridge,
      workspaceController: workspace.workspaceController,
      workspaceShellController: workspace.workspaceShellController,
      workspaceLinksController: workspace.workspaceLinksController,
      appShellPlatformBridge: foundation.appShellPlatformBridge,
      environmentBookmarkSynchronizer: foundation.environmentBookmarkSynchronizer,
      environmentController: foundation.environmentController,
      thumbnailController: workspace.thumbnailController,
      videoConversionCoordinator: workspace.videoConversionCoordinator,
      autosaveTimer: autosaveTimer,
      appLifecycleListener: appLifecycleListener,
    );
  }
}

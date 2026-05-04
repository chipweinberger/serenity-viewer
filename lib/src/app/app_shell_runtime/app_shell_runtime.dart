import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime_factory.dart';
import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/app/platform/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/app/sry_document/sry_document_coordinator.dart';
import 'package:serenity_viewer/src/asset_window/interaction/asset_window_interaction_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/video_tools/media_bridge.dart';
import 'package:serenity_viewer/src/video_tools/video_conversion_coordinator.dart';
import 'package:serenity_viewer/src/workspace/controller/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/session/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppShellRuntime {
  AppShellRuntime.assembled({
    required this.dependencies,
    required this.state,
    required this.foundation,
    required this.documents,
    required this.workspace,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final ShellDependencies dependencies;
  final AppShellRuntimeStateServices state;
  final AppShellRuntimeFoundationServices foundation;
  final AppShellRuntimeDocumentServices documents;
  final AppShellRuntimeWorkspaceServices workspace;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  static AppShellRuntime create(AppShellRuntimeConfig config) {
    return AppShellRuntimeFactory(config).create();
  }

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspace.workspaceShellController.tracking.cancel();
    dependencies.workspaceViewTrackingState.dispose();
    dependencies.windowInteractionState.dispose();
    workspace.thumbnailController.dispose();
    foundation.mediaBridge.dispose();
    state.handles.dispose();
  }
}

class AppShellRuntimeStateServices {
  const AppShellRuntimeStateServices({
    required this.handles,
    required this.persistenceState,
    required this.chromeState,
    required this.windowInteractionState,
    required this.workspaceViewTrackingState,
    required this.workspaceViewportState,
    required this.thumbnailRefreshState,
  });

  final ShellHandles handles;
  final AppEnvironmentState persistenceState;
  final ChromeState chromeState;
  final AssetWindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
}

class AppShellRuntimeFoundationServices {
  const AppShellRuntimeFoundationServices({
    required this.chromeController,
    required this.mediaBridge,
    required this.appShellPlatformBridge,
    required this.environmentBookmarkSynchronizer,
    required this.environmentController,
  });

  final ChromeController chromeController;
  final MediaBridge mediaBridge;
  final AppShellPlatformBridge appShellPlatformBridge;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final EnvironmentController environmentController;
}

class AppShellRuntimeDocumentServices {
  const AppShellRuntimeDocumentServices({required this.sryDocumentCoordinator});

  final SryDocumentCoordinator sryDocumentCoordinator;
}

class AppShellRuntimeWorkspaceServices {
  const AppShellRuntimeWorkspaceServices({
    required this.thumbnailController,
    required this.videoConversionCoordinator,
    required this.workspaceLinksController,
    required this.workspaceController,
    required this.workspaceShellController,
  });

  final ThumbnailController thumbnailController;
  final VideoConversionCoordinator videoConversionCoordinator;
  final LinksController workspaceLinksController;
  final WorkspaceController workspaceController;
  final WorkspaceShellController workspaceShellController;
}

class AppShellRuntimeConfig {
  const AppShellRuntimeConfig({
    required this.isRunningInWidgetTest,
    required this.dependencies,
    required this.shell,
    required this.environment,
    required this.workspace,
  });

  final bool isRunningInWidgetTest;
  final ShellDependencies dependencies;
  final AppShellRuntimeShellConfig shell;
  final AppShellRuntimeEnvironmentConfig environment;
  final AppShellRuntimeWorkspaceConfig workspace;
}

class AppShellRuntimeShellConfig {
  const AppShellRuntimeShellConfig({
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

class AppShellRuntimeEnvironmentConfig {
  const AppShellRuntimeEnvironmentConfig({
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

class AppShellRuntimeWorkspaceConfig {
  const AppShellRuntimeWorkspaceConfig({
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

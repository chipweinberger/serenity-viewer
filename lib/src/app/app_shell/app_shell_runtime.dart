import 'dart:async';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/app_shell_runtime_factory.dart';
import 'package:serenity_viewer/src/app/dependencies/shell_dependencies.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/app/platform/app_shell_platform_bridge.dart';
import 'package:serenity_viewer/src/app/sry_document/sry_document_coordinator.dart';
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
    required this.chromeController,
    required this.sryDocumentCoordinator,
    required this.mediaBridge,
    required this.workspaceController,
    required this.workspaceShellController,
    required this.workspaceLinksController,
    required this.appShellPlatformBridge,
    required this.environmentBookmarkSynchronizer,
    required this.environmentController,
    required this.thumbnailController,
    required this.videoConversionCoordinator,
    required this.autosaveTimer,
    required this.appLifecycleListener,
  });

  final ShellDependencies dependencies;
  final ChromeController chromeController;
  final SryDocumentCoordinator sryDocumentCoordinator;
  final MediaBridge mediaBridge;
  final WorkspaceController workspaceController;
  final WorkspaceShellController workspaceShellController;
  final LinksController workspaceLinksController;
  final AppShellPlatformBridge appShellPlatformBridge;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final EnvironmentController environmentController;
  final ThumbnailController thumbnailController;
  final VideoConversionCoordinator videoConversionCoordinator;
  final Timer autosaveTimer;
  final AppLifecycleListener appLifecycleListener;

  ShellHandles get handles => dependencies.handles;
  AppEnvironmentState get persistenceState => dependencies.persistenceState;
  ChromeState get chromeState => dependencies.chromeState;
  WorkspaceViewTrackingState get workspaceViewTrackingState => dependencies.workspaceViewTrackingState;
  WorkspaceViewportState get workspaceViewportState => dependencies.workspaceViewportState;
  ThumbnailRefreshState get thumbnailRefreshState => dependencies.thumbnailRefreshState;

  static AppShellRuntime create({
    required bool isRunningInWidgetTest,
    required ShellDependencies dependencies,
    required String Function() windowTitle,
    required BuildContext Function() context,
    required bool Function() mounted,
    required StateSetter commitStateChange,
    required ValueChanged<String> showMessage,
    required Environment Function() seedEnvironment,
    required ValueChanged<Environment> updateEnvironment,
    required void Function(Workspace workspace, {bool queueThumbnail}) replaceWorkspace,
    required Future<void> Function() saveEnvironment,
    required String Function(String prefix) newId,
    required int Function(String value) colorFromDigest,
    required Workspace? Function() activeWorkspace,
    required List<Workspace> Function() workspaces,
    required List<Workspace> Function() openWorkspaces,
    required Window? Function() focusedWindowOrNull,
    required void Function({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail})
    setWorkspaceViewport,
    required SerenityShowWorkspaceScreen showWorkspaceScreen,
    required SerenityShowLibraryScreen showLibraryScreen,
    required VoidCallback toggleExpose,
    required ValueChanged<String> toggleVideoPlayback,
  }) {
    return AppShellRuntimeFactory(
      AppShellRuntimeConfig(
        isRunningInWidgetTest: isRunningInWidgetTest,
        dependencies: dependencies,
        windowTitle: windowTitle,
        context: context,
        mounted: mounted,
        commitStateChange: commitStateChange,
        showMessage: showMessage,
        seedEnvironment: seedEnvironment,
        updateEnvironment: updateEnvironment,
        replaceWorkspace: replaceWorkspace,
        saveEnvironment: saveEnvironment,
        newId: newId,
        colorFromDigest: colorFromDigest,
        activeWorkspace: activeWorkspace,
        workspaces: workspaces,
        openWorkspaces: openWorkspaces,
        focusedWindowOrNull: focusedWindowOrNull,
        setWorkspaceViewport: setWorkspaceViewport,
        showWorkspaceScreen: showWorkspaceScreen,
        showLibraryScreen: showLibraryScreen,
        toggleExpose: toggleExpose,
        toggleVideoPlayback: toggleVideoPlayback,
      ),
    ).create();
  }

  void dispose() {
    autosaveTimer.cancel();
    appLifecycleListener.dispose();
    workspaceShellController.tracking.cancel();
    dependencies.workspaceViewTrackingState.dispose();
    dependencies.windowInteractionState.dispose();
    thumbnailController.dispose();
    mediaBridge.dispose();
    handles.dispose();
  }
}

class AppShellRuntimeConfig {
  const AppShellRuntimeConfig({
    required this.isRunningInWidgetTest,
    required this.dependencies,
    required this.windowTitle,
    required this.context,
    required this.mounted,
    required this.commitStateChange,
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
  final ShellDependencies dependencies;
  final String Function() windowTitle;
  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
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

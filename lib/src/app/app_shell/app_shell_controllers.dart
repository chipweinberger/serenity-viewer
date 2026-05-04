import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_shell/app_shell_derived_state.dart';
import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime.dart';
import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_media_import_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_navigation_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_ui_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_window_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_window_history_controller.dart';
import 'package:serenity_viewer/src/app/app_shell/controllers/app_shell_workspace_geometry_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';
import 'package:serenity_viewer/src/workspace/session/recently_closed_window_entry.dart';

class AppShellController {
  AppShellController({
    required this.context,
    required this.mounted,
    required this.commitStateChange,
    required this.recentlyClosedWindows,
    required this.maxRecentlyClosedWindows,
    required this.imageExtensions,
    required this.videoExtensions,
    required this.state,
    required this.derived,
    required this.foundation,
    required this.documents,
    required this.workspace,
  }) {
    navigation = AppShellNavigationController(chromeController: foundation.chromeController);
    ui = AppShellUiController(
      context: context,
      persistenceState: state.persistenceState,
      updateEnvironment: environment.updateEnvironment,
    );
    windowHistory = AppShellWindowHistoryController(
      environment: () => state.persistenceState.environment,
      workspaces: () => derived.workspaces,
      activeWorkspace: () => derived.activeWorkspaceOrNull,
      recentlyClosedWindows: recentlyClosedWindows,
      workspaceController: workspace.workspaceController,
      updateEnvironment: environment.updateEnvironment,
      replaceWorkspace: environment.replaceWorkspace,
      commitStateChange: commitStateChange,
      showMessage: ui.showMessage,
      showWorkspaceScreen: navigation.showWorkspaceScreen,
      screen: () => state.chromeState.screen,
      maxRecentlyClosedWindows: maxRecentlyClosedWindows,
    );
    window = AppShellWindowController(
      context: context,
      mounted: mounted,
      chromeState: state.chromeState,
      environment: () => state.persistenceState.environment,
      activeWorkspace: () => derived.activeWorkspace,
      activeWorkspaceOrNull: () => derived.activeWorkspaceOrNull,
      workspaceController: workspace.workspaceController,
      showMessage: ui.showMessage,
    );
    geometry = AppShellWorkspaceGeometryController(
      persistenceState: state.persistenceState,
      workspaceViewportState: state.workspaceViewportState,
      thumbnailController: workspace.thumbnailController,
      replaceWorkspace: environment.replaceWorkspace,
    );
    mediaImport = AppShellMediaImportController(
      imageExtensions: imageExtensions,
      videoExtensions: videoExtensions,
      persistenceState: state.persistenceState,
      activeWorkspace: () => derived.activeWorkspace,
      videoConversionCoordinator: workspace.videoConversionCoordinator,
      createFileBookmark: foundation.appShellPlatformBridge.createFileBookmark,
      mediaBridge: foundation.mediaBridge,
      newId: geometry.newId,
      colorFromDigest: geometry.colorFromDigest,
      updateEnvironment: environment.updateEnvironment,
      thumbnailController: workspace.thumbnailController,
      showMessage: ui.showMessage,
    );
  }

  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final List<RecentlyClosedWindowEntry> recentlyClosedWindows;
  final int maxRecentlyClosedWindows;
  final List<String> imageExtensions;
  final List<String> videoExtensions;
  final AppShellRuntimeStateServices state;
  final AppShellDerivedState derived;
  final AppShellRuntimeFoundationServices foundation;
  final AppShellRuntimeDocumentServices documents;
  final AppShellRuntimeWorkspaceServices workspace;
  late final AppShellNavigationController navigation;
  late final AppShellUiController ui;
  late final AppShellWindowHistoryController windowHistory;
  late final AppShellWindowController window;
  late final AppShellWorkspaceGeometryController geometry;
  late final AppShellMediaImportController mediaImport;

  EnvironmentController get environment {
    return foundation.environmentController;
  }

  ChromeController get chrome {
    return foundation.chromeController;
  }
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_derived_state.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/environment/session/environment_store.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/media_import_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_navigation_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/controllers/window_controller.dart';
import 'package:serenity_viewer/src/app/controllers/window_history_controller.dart';
import 'package:serenity_viewer/src/app/controllers/workspace_geometry_controller.dart';
import 'package:serenity_viewer/src/workspace/window/session/recently_closed_window_entry.dart';

class AppActions {
  AppActions({
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
    navigation = AppNavigationController(appUiController: foundation.appUiController);
    feedback = AppFeedbackController(
      context: context,
      environmentStoreState: state.environmentStoreState,
      updateEnvironment: environmentStore.updateEnvironment,
    );
    windowHistory = WindowHistoryController(
      environment: () => state.environmentStoreState.environment,
      workspaces: () => derived.workspaces,
      activeWorkspace: () => derived.activeWorkspaceOrNull,
      recentlyClosedWindows: recentlyClosedWindows,
      workspaceController: workspace.workspaceController,
      updateEnvironment: environmentStore.updateEnvironment,
      replaceWorkspace: environmentStore.replaceWorkspace,
      commitStateChange: commitStateChange,
      showMessage: feedback.showMessage,
      showWorkspaceScreen: navigation.showWorkspaceScreen,
      screen: () => state.appUiState.screen,
      maxRecentlyClosedWindows: maxRecentlyClosedWindows,
    );
    window = WindowController(
      context: context,
      mounted: mounted,
      appUiState: state.appUiState,
      environment: () => state.environmentStoreState.environment,
      activeWorkspace: () => derived.activeWorkspace,
      activeWorkspaceOrNull: () => derived.activeWorkspaceOrNull,
      workspaceController: workspace.workspaceController,
      showMessage: feedback.showMessage,
    );
    geometry = WorkspaceGeometryController(
      environmentStoreState: state.environmentStoreState,
      workspaceViewportState: state.workspaceViewportState,
      thumbnailController: workspace.thumbnailController,
      replaceWorkspace: environmentStore.replaceWorkspace,
    );
    mediaImport = MediaImportController(
      imageExtensions: imageExtensions,
      videoExtensions: videoExtensions,
      environmentStoreState: state.environmentStoreState,
      activeWorkspace: () => derived.activeWorkspace,
      videoConversionCoordinator: workspace.videoConversionCoordinator,
      createFileBookmark: foundation.platformBridge.createFileBookmark,
      mediaBridge: foundation.mediaBridge,
      newId: geometry.newId,
      colorFromDigest: geometry.colorFromDigest,
      updateEnvironment: environmentStore.updateEnvironment,
      thumbnailController: workspace.thumbnailController,
      showMessage: feedback.showMessage,
    );
  }

  final BuildContext Function() context;
  final bool Function() mounted;
  final StateSetter commitStateChange;
  final List<RecentlyClosedWindowEntry> recentlyClosedWindows;
  final int maxRecentlyClosedWindows;
  final List<String> imageExtensions;
  final List<String> videoExtensions;
  final AppStateServices state;
  final AppDerivedState derived;
  final AppFoundation foundation;
  final AppDocument documents;
  final AppWorkspaceServices workspace;
  late final AppNavigationController navigation;
  late final AppFeedbackController feedback;
  late final WindowHistoryController windowHistory;
  late final WindowController window;
  late final WorkspaceGeometryController geometry;
  late final MediaImportController mediaImport;

  EnvironmentStore get environmentStore {
    return foundation.environmentStore;
  }

  AppUiController get appUi {
    return foundation.appUiController;
  }
}

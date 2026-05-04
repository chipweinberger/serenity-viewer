import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_providers.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _appUiState = AppUiState();
  final _environmentStoreState = EnvironmentStoreState();
  final _windowInteractionState = WindowInteractionState();
  final _workspaceViewTrackingState = WorkspaceViewTrackingState();
  final _workspaceViewportState = WorkspaceViewportState();
  final _thumbnailRefreshState = ThumbnailRefreshState();
  final _workspaceWindowHistoryState = WorkspaceWindowHistoryState();
  final _uiHandles = AppUiHandles();
  late final AppRuntime _runtime;
  late final AppFeedbackController _feedback;
  late final AppSettingsController _settings;
  late final DocumentPersistenceController _documentPersistence;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  void initState() {
    super.initState();
    _runtime = AppRuntime.create(
      isRunningInWidgetTest: _isRunningInWidgetTest,
      environmentStoreState: _environmentStoreState,
      appUiState: _appUiState,
      windowInteractionState: _windowInteractionState,
      workspaceViewTrackingState: _workspaceViewTrackingState,
      workspaceViewportState: _workspaceViewportState,
      thumbnailRefreshState: _thumbnailRefreshState,
      workspaceWindowHistoryState: _workspaceWindowHistoryState,
      windowTitle: () => deriveWindowTitle(_environmentStoreState),
      context: () => context,
      mounted: () => mounted,
      showMessage: _showMessage,
      seedEnvironment: buildSeedEnvironment,
      updateEnvironment: (environment) => _runtime.environmentStore.updateEnvironment(environment),
      replaceWorkspace: (workspace, {queueThumbnail = true}) {
        _runtime.environmentStore.replaceWorkspace(workspace, queueThumbnail: queueThumbnail);
      },
      saveEnvironment: () => _documentPersistence.saveEnvironment(),
      newId: newSerenityId,
      colorFromDigest: assetColorValueFromDigest,
      activeWorkspace: () => deriveActiveWorkspaceOrNull(_environmentStoreState),
      workspaces: () => deriveWorkspaces(_environmentStoreState),
      openWorkspaces: () => deriveOpenWorkspaces(_environmentStoreState),
      focusedWindowOrNull: () => _runtime.workspaceWindowController.focusedWindowOrNull(),
      setWorkspaceViewport: ({required workspaceId, center, zoom, queueThumbnail = true}) {
        _runtime.workspaceViewportSessionController.setWorkspaceViewport(
          workspaceId: workspaceId,
          center: center,
          zoom: zoom,
          queueThumbnail: queueThumbnail,
        );
      },
      showWorkspaceScreen:
          ({
            WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
            bool resetEditMode = true,
            bool clearExposeSelection = true,
            bool refreshWorkspaceTracking = true,
          }) => _runtime.appUiController.showWorkspaceScreen(
            workspaceLayoutMode: workspaceLayoutMode,
            resetEditMode: resetEditMode,
            clearExposeSelection: clearExposeSelection,
            refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
          ),
      showLibraryScreen:
          ({
            bool resetEditMode = true,
            bool clearExposeSelection = true,
            bool refreshWorkspaceTracking = true,
          }) => _runtime.appUiController.showLibraryScreen(
            resetEditMode: resetEditMode,
            clearExposeSelection: clearExposeSelection,
            refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
          ),
      toggleExpose: () => _runtime.appUiController.toggleExpose(),
      toggleVideoPlayback: (windowId) => _runtime.workspaceWindowController.toggleVideoPlayback(windowId),
    );
    _feedback = AppFeedbackController(context: () => context);
    _settings = AppSettingsController(
      context: () => context,
      environmentStoreState: _environmentStoreState,
      updateEnvironment: _runtime.environmentStore.updateEnvironment,
    );
    _documentPersistence = DocumentPersistenceController(
      environmentStoreState: _environmentStoreState,
      environmentStore: _runtime.environmentStore,
      platformBridge: _runtime.platformBridge,
      environmentBookmarkSynchronizer: _runtime.environmentBookmarkSynchronizer,
      documentCoordinator: _runtime.documentCoordinator,
      mounted: () => mounted,
      seedEnvironment: buildSeedEnvironment,
      isRunningInWidgetTest: _isRunningInWidgetTest,
    );
    _documentPersistence.restoreEnvironment();
  }

  @override
  void dispose() {
    _runtime.dispose();
    _environmentStoreState.dispose();
    _appUiState.dispose();
    _windowInteractionState.dispose();
    _workspaceViewTrackingState.dispose();
    _workspaceViewportState.dispose();
    _thumbnailRefreshState.dispose();
    _workspaceWindowHistoryState.dispose();
    _uiHandles.dispose();
    super.dispose();
  }

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      appUiState: _appUiState,
      environmentStoreState: _environmentStoreState,
      windowInteractionState: _windowInteractionState,
      workspaceViewportState: _workspaceViewportState,
      thumbnailRefreshState: _thumbnailRefreshState,
      workspaceWindowHistoryState: _workspaceWindowHistoryState,
      workspaceViewTrackingState: _workspaceViewTrackingState,
      uiHandles: _uiHandles,
      feedback: _feedback,
      settings: _settings,
      runtime: _runtime,
      child: const AppShell(),
    );
  }
}

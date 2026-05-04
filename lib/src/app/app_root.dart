import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_providers.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _stateStore = AppStateStore();
  final _uiHandles = AppUiHandles();
  late final AppRuntime _runtime;
  late final AppFeedbackController _feedback;
  late final AppSettingsController _settings;
  late final DocumentPersistenceController _documentPersistence;

  AppStateStore get _state => _stateStore;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Widget _buildContent(BuildContext context) {
    if (_state.environmentStoreState.isLoading || _state.environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return const AppMainView();
  }

  @override
  void initState() {
    super.initState();
    _runtime = AppRuntime.create(
      isRunningInWidgetTest: _isRunningInWidgetTest,
      environmentStoreState: _stateStore.environmentStoreState,
      appUiState: _stateStore.appUiState,
      windowInteractionState: _stateStore.windowInteractionState,
      workspaceViewTrackingState: _stateStore.workspaceViewTrackingState,
      workspaceViewportState: _stateStore.workspaceViewportState,
      thumbnailRefreshState: _stateStore.thumbnailRefreshState,
      workspaceWindowHistoryState: _stateStore.workspaceWindowHistoryState,
      windowTitle: () => deriveWindowTitle(_stateStore),
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
      activeWorkspace: () => deriveActiveWorkspaceOrNull(_stateStore),
      workspaces: () => deriveWorkspaces(_stateStore),
      openWorkspaces: () => deriveOpenWorkspaces(_stateStore),
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
      environmentStoreState: _state.environmentStoreState,
      updateEnvironment: _runtime.environmentStore.updateEnvironment,
    );
    _documentPersistence = DocumentPersistenceController(
      state: _state,
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
    _stateStore.dispose();
    _uiHandles.dispose();
    super.dispose();
  }

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _stateStore.shellListenable,
      builder: (context, _) {
        return AppProviders(
          stateStore: _stateStore,
          uiHandles: _uiHandles,
          feedback: _feedback,
          settings: _settings,
          runtime: _runtime,
          child: AppMenu(
            child: Focus(
              focusNode: _uiHandles.focusNode,
              autofocus: true,
              onKeyEvent: (_, event) => _runtime.workspaceShortcutController.onKeyEvent(event),
              child: Scaffold(body: SafeArea(top: false, child: _buildContent(context))),
            ),
          ),
        );
      },
    );
  }
}

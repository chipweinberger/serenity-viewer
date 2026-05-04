import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/runtime/factories/app_workspace_factory.dart';
import 'package:serenity_viewer/src/app/app_shell.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
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
  final _environmentWindowHistoryState = EnvironmentWindowHistoryState();
  final _uiHandles = AppUiHandles();
  late final AppRuntime _runtime;
  late final DocumentPersistenceController _documentPersistence;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  AppRuntime _createRuntime() {
    return createAppRuntime(
      environmentStoreState: _environmentStoreState,
      workspaceState: WorkspaceState(
        appUiState: _appUiState,
        windowInteractionState: _windowInteractionState,
        workspaceViewTrackingState: _workspaceViewTrackingState,
        workspaceViewportState: _workspaceViewportState,
        thumbnailRefreshState: _thumbnailRefreshState,
        environmentWindowHistoryState: _environmentWindowHistoryState,
      ),
      workspaceRuntime: WorkspaceRuntime(
        isRunningInWidgetTest: _isRunningInWidgetTest,
        context: () => context,
        mounted: () => mounted,
        showMessage: _showMessage,
      ),
      workspaceQueries: WorkspaceQueries(
        activeWorkspace: () => deriveActiveWorkspaceOrNull(_environmentStoreState),
        workspaces: () => deriveWorkspaces(_environmentStoreState),
        openWorkspaces: () => deriveOpenWorkspaces(_environmentStoreState),
        focusedWindowOrNull: () => _runtime.workspaceController.window.focusedWindowOrNull(),
      ),
      workspaceActions: WorkspaceActions(
        newId: newSerenityId,
        colorFromDigest: assetColorValueFromDigest,
        setWorkspaceViewport: ({required workspaceId, center, zoom, queueThumbnail = true}) {
          _runtime.workspaceController.viewport.setWorkspaceViewport(
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
            ({bool resetEditMode = true, bool clearExposeSelection = true, bool refreshWorkspaceTracking = true}) =>
                _runtime.appUiController.showLibraryScreen(
                  resetEditMode: resetEditMode,
                  clearExposeSelection: clearExposeSelection,
                  refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
                ),
        toggleExpose: () => _runtime.appUiController.toggleExpose(),
        toggleVideoPlayback: (windowId) => _runtime.workspaceController.playback.toggleVideoPlayback(windowId),
      ),
      windowTitle: () => deriveWindowTitle(_environmentStoreState),
      saveEnvironment: () => _documentPersistence.saveEnvironment(),
      documentCreation: DocumentCreationActions(seedEnvironment: buildSeedEnvironment),
    );
  }

  DocumentPersistenceController _createDocumentPersistenceController() {
    return DocumentPersistenceController(
      environmentStoreState: _environmentStoreState,
      environmentStore: _runtime.environmentStore,
      platformBridge: _runtime.platformBridge,
      environmentBookmarkSynchronizer: _runtime.environmentBookmarkSynchronizer,
      documentCoordinator: _runtime.documentCoordinator,
      mounted: () => mounted,
      seedEnvironment: buildSeedEnvironment,
      isRunningInWidgetTest: _isRunningInWidgetTest,
    );
  }

  List<SingleChildWidget> _buildProviders() {
    return [
      Provider<AppUiHandles>.value(value: _uiHandles),
      Provider<AppFeedbackController>(create: (context) => AppFeedbackController(context: () => context)),
      Provider<AppSettingsController>(
        create: (context) => AppSettingsController(
          context: () => context,
          environmentStoreState: _environmentStoreState,
          updateEnvironment: _runtime.environmentStore.updateEnvironment,
        ),
      ),
      ChangeNotifierProvider.value(value: _appUiState),
      ChangeNotifierProvider.value(value: _environmentStoreState),
      ChangeNotifierProvider.value(value: _windowInteractionState),
      ChangeNotifierProvider.value(value: _workspaceViewportState),
      ChangeNotifierProvider.value(value: _thumbnailRefreshState),
      ChangeNotifierProvider.value(value: _environmentWindowHistoryState),
      ChangeNotifierProvider.value(value: _workspaceViewTrackingState),
      Provider<AppUiController>.value(value: _runtime.appUiController),
      Provider<SharedVideoControllerPool>.value(value: _runtime.sharedVideoControllerPool),
      Provider<PlatformBridge>.value(value: _runtime.platformBridge),
      Provider<EnvironmentStore>.value(value: _runtime.environmentStore),
      Provider<DocumentCoordinator>.value(value: _runtime.documentCoordinator),
      Provider<WorkspaceController>.value(value: _runtime.workspaceController),
      Provider<EnvironmentController>.value(value: _runtime.environmentController),
      Provider<EnvironmentWindowHistoryController>.value(value: _runtime.environmentWindowHistoryController),
    ];
  }

  @override
  void initState() {
    super.initState();
    _runtime = _createRuntime();
    _documentPersistence = _createDocumentPersistenceController();
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
    _environmentWindowHistoryState.dispose();
    _uiHandles.dispose();
    super.dispose();
  }

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: _buildProviders(), child: const AppShell());
  }
}

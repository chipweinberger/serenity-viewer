import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/app_shell.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/serenity_identity.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_state.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';

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
  late final DocumentPersistenceController _documentPersistence;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  AppRuntime _createRuntime() {
    return createAppRuntime(
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
      ChangeNotifierProvider.value(value: _workspaceWindowHistoryState),
      ChangeNotifierProvider.value(value: _workspaceViewTrackingState),
      Provider<AppUiController>.value(value: _runtime.appUiController),
      Provider<SharedVideoControllerPool>.value(value: _runtime.sharedVideoControllerPool),
      Provider<PlatformBridge>.value(value: _runtime.platformBridge),
      Provider<EnvironmentStore>.value(value: _runtime.environmentStore),
      Provider<DocumentCoordinator>.value(value: _runtime.documentCoordinator),
      Provider<WorkspaceController>.value(value: _runtime.workspaceController),
      Provider<EnvironmentController>.value(value: _runtime.environmentController),
      Provider<WorkspaceExposeLayoutController>.value(value: _runtime.workspaceExposeLayoutController),
      Provider<WorkspaceLinksController>.value(value: _runtime.workspaceLinksController),
      Provider<WorkspaceLinksLauncher>.value(value: _runtime.workspaceLinksLauncher),
      Provider<WorkspaceLinksPrompts>.value(value: _runtime.workspaceLinksPrompts),
      Provider<ThumbnailController>.value(value: _runtime.thumbnailController),
      Provider<WorkspaceWindowHistoryController>.value(value: _runtime.workspaceWindowHistoryController),
      Provider<WorkspaceMediaImportController>.value(value: _runtime.workspaceMediaImportController),
      Provider<WorkspaceWindowController>.value(value: _runtime.workspaceWindowController),
      Provider<WorkspaceViewportSessionController>.value(value: _runtime.workspaceViewportSessionController),
      Provider<WorkspaceCollateController>.value(value: _runtime.workspaceCollateController),
      Provider<WorkspaceVideoConversionController>.value(value: _runtime.workspaceVideoConversionController),
      Provider<WorkspaceAssetPickerController>.value(value: _runtime.workspaceAssetPickerController),
      Provider<WorkspaceShortcutController>.value(value: _runtime.workspaceShortcutController),
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
    return MultiProvider(
      providers: _buildProviders(),
      child: const AppShell(),
    );
  }
}

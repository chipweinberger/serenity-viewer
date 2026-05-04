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
import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/settings/app_settings_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_refresh_state.dart';
import 'package:serenity_viewer/src/workspace/tracking/workspace_view_tracking_state.dart';
import 'package:serenity_viewer/src/workspace/viewport/workspace_viewport_state.dart';

class AppRootObjects {
  AppRootObjects()
    : appUiState = AppUiState(),
      environmentStoreState = EnvironmentStoreState(),
      windowInteractionState = WindowInteractionState(),
      workspaceViewTrackingState = WorkspaceViewTrackingState(),
      workspaceViewportState = WorkspaceViewportState(),
      thumbnailRefreshState = ThumbnailRefreshState(),
      environmentWindowHistoryState = EnvironmentWindowHistoryState(),
      uiHandles = AppUiHandles();

  final AppUiState appUiState;
  final EnvironmentStoreState environmentStoreState;
  final WindowInteractionState windowInteractionState;
  final WorkspaceViewTrackingState workspaceViewTrackingState;
  final WorkspaceViewportState workspaceViewportState;
  final ThumbnailRefreshState thumbnailRefreshState;
  final EnvironmentWindowHistoryState environmentWindowHistoryState;
  final AppUiHandles uiHandles;

  void dispose() {
    environmentStoreState.dispose();
    appUiState.dispose();
    windowInteractionState.dispose();
    workspaceViewTrackingState.dispose();
    workspaceViewportState.dispose();
    thumbnailRefreshState.dispose();
    environmentWindowHistoryState.dispose();
    uiHandles.dispose();
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _rootObjects = AppRootObjects();
  late final AppRuntime _runtime;
  late final DocumentPersistenceController _documentPersistence;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  AppRuntime _createRuntime() {
    final rootObjects = _rootObjects;
    return createAppRuntime(
      rootObjects: rootObjects,
      context: () => context,
      windowTitle: () => deriveWindowTitle(rootObjects.environmentStoreState),
      mounted: () => mounted,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      seedEnvironment: buildSeedEnvironment,
      saveEnvironment: () => _documentPersistence.saveEnvironment(),
      showMessage: _showMessage,
    );
  }

  DocumentPersistenceController _createDocumentPersistenceController() {
    return DocumentPersistenceController(
      environmentStoreState: _rootObjects.environmentStoreState,
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
      Provider<AppUiHandles>.value(value: _rootObjects.uiHandles),
      Provider<AppFeedbackController>(create: (context) => AppFeedbackController(context: () => context)),
      Provider<AppSettingsController>(
        create: (context) => AppSettingsController(
          context: () => context,
          environmentStoreState: _rootObjects.environmentStoreState,
          updateEnvironment: _runtime.environmentStore.updateEnvironment,
        ),
      ),
      ChangeNotifierProvider.value(value: _rootObjects.appUiState),
      ChangeNotifierProvider.value(value: _rootObjects.environmentStoreState),
      ChangeNotifierProvider.value(value: _rootObjects.windowInteractionState),
      ChangeNotifierProvider.value(value: _rootObjects.workspaceViewportState),
      ChangeNotifierProvider.value(value: _rootObjects.thumbnailRefreshState),
      ChangeNotifierProvider.value(value: _rootObjects.environmentWindowHistoryState),
      ChangeNotifierProvider.value(value: _rootObjects.workspaceViewTrackingState),
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
    _rootObjects.dispose();
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

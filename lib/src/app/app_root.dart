import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/media/import/workspace_media_import_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_expose_layout_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_viewport_session_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_launcher.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_prompts.dart';
import 'package:serenity_viewer/src/workspace/thumbnails/thumbnail_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
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
  DocumentCoordinator get _documentCoordinator => _runtime.documentCoordinator;
  AppUiController get _appUiController => _runtime.appUiController;
  SharedVideoControllerPool get _sharedVideoControllerPool => _runtime.sharedVideoControllerPool;
  PlatformBridge get _platformBridge => _runtime.platformBridge;
  EnvironmentStore get _environmentStore => _runtime.environmentStore;
  EnvironmentBookmarkSynchronizer get _environmentBookmarkSynchronizer => _runtime.environmentBookmarkSynchronizer;
  WorkspaceController get _workspaceController => _runtime.workspaceController;
  EnvironmentController get _environmentController => _runtime.environmentController;
  WorkspaceExposeLayoutController get _workspaceExposeLayoutController => _runtime.workspaceExposeLayoutController;
  WorkspaceLinksController get _workspaceLinksController => _runtime.workspaceLinksController;
  WorkspaceLinksLauncher get _workspaceLinksLauncher => _runtime.workspaceLinksLauncher;
  WorkspaceLinksPrompts get _workspaceLinksPrompts => _runtime.workspaceLinksPrompts;
  ThumbnailController get _thumbnailController => _runtime.thumbnailController;
  WorkspaceWindowHistoryController get _workspaceWindowHistoryController => _runtime.workspaceWindowHistoryController;
  WorkspaceMediaImportController get _workspaceMediaImportController => _runtime.workspaceMediaImportController;
  WorkspaceWindowController get _workspaceWindowController => _runtime.workspaceWindowController;
  WorkspaceViewportSessionController get _workspaceViewportSessionController =>
      _runtime.workspaceViewportSessionController;
  WorkspaceCollateController get _workspaceCollateController => _runtime.workspaceCollateController;
  WorkspaceVideoConversionController get _workspaceVideoConversionController => _runtime.workspaceVideoConversionController;
  WorkspaceAssetPickerController get _workspaceAssetPickerController => _runtime.workspaceAssetPickerController;
  WorkspaceShortcutController get _workspaceShortcutController => _runtime.workspaceShortcutController;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  AppMainViewBindings _buildAppMainViewBindings() {
    return buildAppMainViewBindings(
      state: _state,
      appUiController: _appUiController,
      sharedVideoControllerPool: _sharedVideoControllerPool,
      revealAssetInFinder: _platformBridge.revealAssetInFinder,
      workspaceController: _workspaceController,
      environmentController: _environmentController,
      workspaceExposeLayoutController: _workspaceExposeLayoutController,
      workspaceLinksController: _workspaceLinksController,
      workspaceLinksLauncher: _workspaceLinksLauncher,
      workspaceLinksPrompts: _workspaceLinksPrompts,
      thumbnailController: _thumbnailController,
      windowHistoryController: _workspaceWindowHistoryController,
      workspaceMediaImportController: _workspaceMediaImportController,
      workspaceWindowController: _workspaceWindowController,
      workspaceViewportSessionController: _workspaceViewportSessionController,
      workspaceCollateController: _workspaceCollateController,
      uiHandles: _uiHandles,
      mounted: () => mounted,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_state.environmentStoreState.isLoading || _state.environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final bindings = _buildAppMainViewBindings();
    return AppMainView(model: bindings.model, services: bindings.services, actions: bindings.actions);
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
      updateEnvironment: _environmentStore.updateEnvironment,
      replaceWorkspace: _environmentStore.replaceWorkspace,
      saveEnvironment: _documentPersistence.saveEnvironment,
      newId: newSerenityId,
      colorFromDigest: assetColorValueFromDigest,
      activeWorkspace: () => deriveActiveWorkspaceOrNull(_stateStore),
      workspaces: () => deriveWorkspaces(_stateStore),
      openWorkspaces: () => deriveOpenWorkspaces(_stateStore),
      focusedWindowOrNull: _workspaceWindowController.focusedWindowOrNull,
      setWorkspaceViewport: _workspaceViewportSessionController.setWorkspaceViewport,
      showWorkspaceScreen:
          ({
            WorkspaceLayoutMode workspaceLayoutMode = WorkspaceLayoutMode.freeform,
            bool resetEditMode = true,
            bool clearExposeSelection = true,
            bool refreshWorkspaceTracking = true,
          }) => _appUiController.showWorkspaceScreen(
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
          }) => _appUiController.showLibraryScreen(
            resetEditMode: resetEditMode,
            clearExposeSelection: clearExposeSelection,
            refreshWorkspaceTrackingEnabled: refreshWorkspaceTracking,
          ),
      toggleExpose: _appUiController.toggleExpose,
      toggleVideoPlayback: _workspaceWindowController.toggleVideoPlayback,
    );
    _feedback = AppFeedbackController(context: () => context);
    _settings = AppSettingsController(
      context: () => context,
      environmentStoreState: _state.environmentStoreState,
      updateEnvironment: _environmentStore.updateEnvironment,
    );
    _documentPersistence = DocumentPersistenceController(
      state: _state,
      environmentStore: _environmentStore,
      platformBridge: _platformBridge,
      environmentBookmarkSynchronizer: _environmentBookmarkSynchronizer,
      documentCoordinator: _documentCoordinator,
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

  AppMenuBindings _buildAppMenuBindings() {
    return buildAppMenuBindings(
      state: _state,
      appUiController: _appUiController,
      revealAssetInFinder: _platformBridge.revealAssetInFinder,
      documentCoordinator: _documentCoordinator,
      workspaceWindowController: _workspaceWindowController,
      workspaceController: _workspaceController,
      environmentController: _environmentController,
      workspaceVideoConversionController: _workspaceVideoConversionController,
      workspaceWindowHistoryController: _workspaceWindowHistoryController,
      workspaceCollateController: _workspaceCollateController,
      feedback: _feedback,
      settings: _settings,
      openAssets: _workspaceAssetPickerController.pickAndImportAssets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _stateStore.shellListenable,
      builder: (context, _) {
        final menu = _buildAppMenuBindings();
        return AppMenu(
          state: menu.state,
          app: menu.app,
          file: menu.file,
          asset: menu.asset,
          workspace: menu.workspace,
          window: menu.window,
          child: Focus(
            focusNode: _uiHandles.focusNode,
            autofocus: true,
            onKeyEvent: (_, event) => _workspaceShortcutController.onKeyEvent(event),
            child: Scaffold(body: SafeArea(top: false, child: _buildContent(context))),
          ),
        );
      },
    );
  }
}

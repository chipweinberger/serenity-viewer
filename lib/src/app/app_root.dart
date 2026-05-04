import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
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

  Window? _focusedWindowOrNull() {
    return _runtime.workspaceWindowController.focusedWindowOrNull();
  }

  void _replaceWorkspace(Workspace workspace, {bool queueThumbnail = true}) {
    _runtime.environmentStore.replaceWorkspace(workspace, queueThumbnail: queueThumbnail);
  }

  Future<void> _saveEnvironment() {
    return _documentPersistence.saveEnvironment();
  }

  void _setWorkspaceViewport({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = true}) {
    _runtime.workspaceViewportSessionController.setWorkspaceViewport(
      workspaceId: workspaceId,
      center: center,
      zoom: zoom,
      queueThumbnail: queueThumbnail,
    );
  }

  void _toggleExpose() {
    _runtime.appUiController.toggleExpose();
  }

  void _toggleVideoPlayback(String windowId) {
    _runtime.workspaceWindowController.toggleVideoPlayback(windowId);
  }

  void _updateEnvironment(Environment environment) {
    _runtime.environmentStore.updateEnvironment(environment);
  }

  ({AppMainViewModel model, AppMainViewServices services, AppMainViewActions actions}) _buildAppMainViewBindings() {
    return buildAppMainViewBindings(
      state: _state,
      appUiController: _runtime.appUiController,
      sharedVideoControllerPool: _runtime.sharedVideoControllerPool,
      revealAssetInFinder: _runtime.platformBridge.revealAssetInFinder,
      workspaceController: _runtime.workspaceController,
      environmentController: _runtime.environmentController,
      workspaceExposeLayoutController: _runtime.workspaceExposeLayoutController,
      workspaceLinksController: _runtime.workspaceLinksController,
      workspaceLinksLauncher: _runtime.workspaceLinksLauncher,
      workspaceLinksPrompts: _runtime.workspaceLinksPrompts,
      thumbnailController: _runtime.thumbnailController,
      windowHistoryController: _runtime.workspaceWindowHistoryController,
      workspaceMediaImportController: _runtime.workspaceMediaImportController,
      workspaceWindowController: _runtime.workspaceWindowController,
      workspaceViewportSessionController: _runtime.workspaceViewportSessionController,
      workspaceCollateController: _runtime.workspaceCollateController,
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
      updateEnvironment: _updateEnvironment,
      replaceWorkspace: _replaceWorkspace,
      saveEnvironment: _saveEnvironment,
      newId: newSerenityId,
      colorFromDigest: assetColorValueFromDigest,
      activeWorkspace: () => deriveActiveWorkspaceOrNull(_stateStore),
      workspaces: () => deriveWorkspaces(_stateStore),
      openWorkspaces: () => deriveOpenWorkspaces(_stateStore),
      focusedWindowOrNull: _focusedWindowOrNull,
      setWorkspaceViewport: _setWorkspaceViewport,
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
      toggleExpose: _toggleExpose,
      toggleVideoPlayback: _toggleVideoPlayback,
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

  ({
    AppMenuState state,
    AppMenuAppActions app,
    AppMenuFileActions file,
    AppMenuAssetActions asset,
    AppMenuWorkspaceActions workspace,
    AppMenuWindowActions window,
  }) _buildAppMenuBindings() {
    return buildAppMenuBindings(
      state: _state,
      appUiController: _runtime.appUiController,
      revealAssetInFinder: _runtime.platformBridge.revealAssetInFinder,
      documentCoordinator: _runtime.documentCoordinator,
      workspaceWindowController: _runtime.workspaceWindowController,
      workspaceController: _runtime.workspaceController,
      environmentController: _runtime.environmentController,
      workspaceVideoConversionController: _runtime.workspaceVideoConversionController,
      workspaceWindowHistoryController: _runtime.workspaceWindowHistoryController,
      workspaceCollateController: _runtime.workspaceCollateController,
      feedback: _feedback,
      settings: _settings,
      openAssets: _runtime.workspaceAssetPickerController.pickAndImportAssets,
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
            onKeyEvent: (_, event) => _runtime.workspaceShortcutController.onKeyEvent(event),
            child: Scaffold(body: SafeArea(top: false, child: _buildContent(context))),
          ),
        );
      },
    );
  }
}

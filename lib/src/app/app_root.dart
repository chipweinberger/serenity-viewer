import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/media/video/shared_video_controller_pool.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';

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
  AppWorkspaceServices get _workspaceRuntime => _runtime.workspace;
  AppUiController get _appUiController => _runtime.foundation.appUiController;
  SharedVideoControllerPool get _sharedVideoControllerPool => _runtime.foundation.sharedVideoControllerPool;
  PlatformBridge get _platformBridge => _runtime.foundation.platformBridge;
  EnvironmentStore get _environmentStore => _runtime.foundation.environmentStore;
  EnvironmentBookmarkSynchronizer get _environmentBookmarkSynchronizer =>
      _runtime.foundation.environmentBookmarkSynchronizer;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  AppMainViewBindings _buildAppMainViewBindings() {
    return buildAppMainViewBindings(
      state: _state,
      appUiController: _appUiController,
      sharedVideoControllerPool: _sharedVideoControllerPool,
      revealAssetInFinder: _platformBridge.revealAssetInFinder,
      workspaceController: _workspaceRuntime.workspaceController,
      environmentController: _workspaceRuntime.environmentController,
      workspaceExposeLayoutController: _workspaceRuntime.workspaceExposeLayoutController,
      workspaceLinksController: _workspaceRuntime.workspaceLinksController,
      workspaceLinksLauncher: _workspaceRuntime.workspaceLinksLauncher,
      workspaceLinksPrompts: _workspaceRuntime.workspaceLinksPrompts,
      thumbnailController: _workspaceRuntime.thumbnailController,
      windowHistoryController: _workspaceRuntime.workspaceWindowHistoryController,
      workspaceMediaImportController: _workspaceRuntime.workspaceMediaImportController,
      workspaceWindowController: _workspaceRuntime.workspaceWindowController,
      workspaceViewportSessionController: _workspaceRuntime.workspaceViewportSessionController,
      workspaceCollateController: _workspaceRuntime.workspaceCollateController,
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
    _runtime = AppRuntime.create(_buildRuntimeInputs());
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

  AppRuntimeInputs _buildRuntimeInputs() {
    return buildAppRuntimeInputs(
      stateStore: _stateStore,
      uiHandles: _uiHandles,
      context: () => context,
      mounted: () => mounted,
      showMessage: _showMessage,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      environmentStore: () => _environmentStore,
      appUiController: () => _appUiController,
      workspaceWindowController: () => _workspaceRuntime.workspaceWindowController,
      workspaceViewportSessionController: () => _workspaceRuntime.workspaceViewportSessionController,
      documentPersistence: () => _documentPersistence,
    );
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
      workspaceWindowController: _workspaceRuntime.workspaceWindowController,
      workspaceController: _workspaceRuntime.workspaceController,
      environmentController: _workspaceRuntime.environmentController,
      workspaceVideoConversionController: _workspaceRuntime.workspaceVideoConversionController,
      workspaceWindowHistoryController: _workspaceRuntime.workspaceWindowHistoryController,
      workspaceCollateController: _workspaceRuntime.workspaceCollateController,
      feedback: _feedback,
      settings: _settings,
      openAssets: _workspaceRuntime.workspaceAssetPickerController.pickAndImportAssets,
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
            onKeyEvent: (_, event) => _workspaceRuntime.workspaceShortcutController.onKeyEvent(event),
            child: Scaffold(body: SafeArea(top: false, child: _buildContent(context))),
          ),
        );
      },
    );
  }
}

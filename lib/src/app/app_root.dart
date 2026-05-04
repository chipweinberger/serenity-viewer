import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
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
  AppFoundation get _foundation => _runtime.foundation;
  DocumentCoordinator get _documentCoordinator => _runtime.documentCoordinator;
  AppWorkspaceServices get _workspaceRuntime => _runtime.workspace;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  AppMainViewBindings _buildAppMainViewBindings() {
    return buildAppMainViewBindings(
      state: _state,
      appUiController: _foundation.appUiController,
      sharedVideoControllerPool: _foundation.sharedVideoControllerPool,
      revealAssetInFinder: _foundation.platformBridge.revealAssetInFinder,
      workspace: _workspaceRuntime,
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
      updateEnvironment: _foundation.environmentStore.updateEnvironment,
    );
    _documentPersistence = DocumentPersistenceController(
      state: _state,
      environmentStore: _foundation.environmentStore,
      platformBridge: _foundation.platformBridge,
      environmentBookmarkSynchronizer: _foundation.environmentBookmarkSynchronizer,
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
      foundation: () => _foundation,
      workspace: () => _workspaceRuntime,
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
      appUiController: _foundation.appUiController,
      revealAssetInFinder: _foundation.platformBridge.revealAssetInFinder,
      documentCoordinator: _documentCoordinator,
      workspace: _workspaceRuntime,
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

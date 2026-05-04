import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Widget _buildProviders({required Widget child}) {
    return MultiProvider(
      providers: [
        Provider<AppStateStore>.value(value: _stateStore),
        Provider<AppRuntime>.value(value: _runtime),
        Provider<AppUiHandles>.value(value: _uiHandles),
        Provider<ValueGetter<bool>>.value(value: () => mounted),
        Provider<AppFeedbackController>.value(value: _feedback),
        Provider<AppSettingsController>.value(value: _settings),
        Provider<DocumentPersistenceController>.value(value: _documentPersistence),
        ChangeNotifierProvider.value(value: _stateStore.appUiState),
        ChangeNotifierProvider.value(value: _stateStore.environmentStoreState),
        ChangeNotifierProvider.value(value: _stateStore.windowInteractionState),
        ChangeNotifierProvider.value(value: _stateStore.workspaceViewportState),
        ChangeNotifierProvider.value(value: _stateStore.thumbnailRefreshState),
        ChangeNotifierProvider.value(value: _stateStore.workspaceWindowHistoryState),
        ChangeNotifierProvider.value(value: _stateStore.workspaceViewTrackingState),
        Provider.value(value: _runtime.appUiController),
        Provider.value(value: _runtime.sharedVideoControllerPool),
        Provider.value(value: _runtime.platformBridge),
        Provider.value(value: _runtime.environmentStore),
        Provider.value(value: _runtime.environmentBookmarkSynchronizer),
        Provider.value(value: _runtime.documentCoordinator),
        Provider.value(value: _runtime.workspaceController),
        Provider.value(value: _runtime.environmentController),
        Provider.value(value: _runtime.workspaceExposeLayoutController),
        Provider.value(value: _runtime.workspaceLinksController),
        Provider.value(value: _runtime.workspaceLinksLauncher),
        Provider.value(value: _runtime.workspaceLinksPrompts),
        Provider.value(value: _runtime.thumbnailController),
        Provider.value(value: _runtime.workspaceWindowHistoryController),
        Provider.value(value: _runtime.workspaceMediaImportController),
        Provider.value(value: _runtime.workspaceWindowController),
        Provider.value(value: _runtime.workspaceViewportSessionController),
        Provider.value(value: _runtime.workspaceCollateController),
        Provider.value(value: _runtime.workspaceVideoConversionController),
        Provider.value(value: _runtime.workspaceAssetPickerController),
        Provider.value(value: _runtime.workspaceShortcutController),
      ],
      child: child,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_state.environmentStoreState.isLoading || _state.environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final bindings = buildAppMainViewBindings(context);
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _stateStore.shellListenable,
      builder: (context, _) {
        return _buildProviders(
          child: Builder(
            builder: (context) {
              final menu = buildAppMenuBindings(context);
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
          ),
        );
      },
    );
  }
}

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/app/state/app_derived_state.dart';
import 'package:serenity_viewer/src/app/state/app_state_store.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/app/app_menu.dart';
import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';

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

  AppRuntimeState get _state => _runtime.state;
  AppDerivedState get _derivedState => AppDerivedState(_state);
  AppFoundation get _foundation => _runtime.foundation;
  AppDocument get _documents => _runtime.documents;
  AppWorkspaceServices get _workspaceRuntime => _runtime.workspace;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _pickAndImportAssets() async {
    final files = await openFiles(
      acceptedTypeGroups: _workspaceRuntime.workspaceMediaImportController.acceptedTypeGroups,
    );
    await _workspaceRuntime.workspaceMediaImportController.importFiles(files);
  }

  Future<void> _confirmCollateWorkspaceWindows() async {
    final collatableWindowCount = _workspaceRuntime.workspaceWindowController.collatableWindowCount();
    if (collatableWindowCount == 0) {
      _feedback.showMessage('There are no image or video windows to collate.');
      return;
    }

    final shouldCollate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Collate Windows?'),
          content: Text(
            'Center and resize $collatableWindowCount image/video window'
            '${collatableWindowCount == 1 ? '' : 's'} into a fixed ${workspaceCollateTargetBox.width.toInt()} × '
            '${workspaceCollateTargetBox.height.toInt()} box?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Collate')),
          ],
        );
      },
    );

    if (shouldCollate == true && mounted) {
      _workspaceRuntime.workspaceWindowController.collateActiveWorkspace();
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_state.environmentStoreState.isLoading || _state.environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AppMainView(
      model: AppMainViewModel(
        uiState: _state.appUiState,
        environment: _state.environmentStoreState.environment!,
        windowTitle: _derivedState.windowTitle,
        workspaces: _derivedState.workspaces,
        openWorkspaces: _derivedState.openWorkspaces,
        activeWorkspace: _derivedState.activeWorkspace,
        activeWorkspaceOrNull: _derivedState.activeWorkspaceOrNull,
        selectedExposeWindowCount: _workspaceRuntime.workspaceController.expose.count(),
        windowInteractionState: _state.windowInteractionState,
        workspaceViewportState: _state.workspaceViewportState,
      ),
      services: AppMainViewServices(
        appUiController: _foundation.appUiController,
        sharedVideoControllerPool: _foundation.sharedVideoControllerPool,
        environmentController: _workspaceRuntime.environmentController,
        workspaceExposeLayoutController: _workspaceRuntime.workspaceExposeLayoutController,
        workspaceLinksController: _workspaceRuntime.workspaceLinksController,
        workspaceLinksLauncher: _workspaceRuntime.workspaceLinksLauncher,
        workspaceLinksPrompts: _workspaceRuntime.workspaceLinksPrompts,
        thumbnailController: _workspaceRuntime.thumbnailController,
        windowHistoryController: _workspaceRuntime.workspaceWindowHistoryController,
        searchController: _uiHandles.searchController,
        tabScrollController: _uiHandles.tabScrollController,
      ),
      actions: AppMainViewActions(
        app: AppMainViewAppActions(
          commitStateChange: setState,
          importFiles: _workspaceRuntime.workspaceMediaImportController.importFiles,
          revealAssetInFinder: _foundation.platformBridge.revealAssetInFinder,
        ),
        window: AppMainViewWindowActions(
          handleOptionGestureHover: _workspaceRuntime.workspaceWindowController.handleOptionGestureHover,
          focusWindow: _workspaceRuntime.workspaceWindowController.focusWindow,
          restorePreviousWindowZOrder: _workspaceRuntime.workspaceWindowController.restorePreviousWindowZOrder,
          moveWindow: _workspaceRuntime.workspaceWindowController.moveWindow,
          resizeWindow: _workspaceRuntime.workspaceWindowController.resizeWindow,
          transformWindowFromTrackpad: _workspaceRuntime.workspaceWindowController.transformWindowFromTrackpad,
          fitWindowToContent: _workspaceRuntime.workspaceWindowController.fitWindowToContent,
          setWindowZoom: _workspaceRuntime.workspaceWindowController.setWindowZoom,
          setVideoPosition: _workspaceRuntime.workspaceWindowController.setVideoPosition,
          cycleVideoPlaybackSpeed: _workspaceRuntime.workspaceWindowController.cycleVideoPlaybackSpeed,
          setWindowIntrinsicSize: _workspaceRuntime.workspaceWindowController.setWindowIntrinsicSize,
          isVideoWindowPaused: _workspaceRuntime.workspaceWindowController.isVideoWindowPaused,
          toggleVideoPlayback: _workspaceRuntime.workspaceWindowController.toggleVideoPlayback,
          setPinnedHoverWindow: _workspaceRuntime.workspaceWindowController.setPinnedHoverWindow,
          clearPinnedHoverWindow: _workspaceRuntime.workspaceWindowController.clearPinnedHoverWindow,
          flashWindow: (windowId) =>
              _workspaceRuntime.workspaceWindowController.flashWindow(windowId, mounted: mounted),
          setActiveGestureWindow: _workspaceRuntime.workspaceWindowController.setActiveGestureWindow,
        ),
        workspace: AppMainViewWorkspaceActions(
          handleWorkspacePanZoomStart: _workspaceRuntime.workspaceWindowController.handleWorkspacePanZoomStart,
          handleWorkspacePanZoomUpdate: _workspaceRuntime.workspaceWindowController.handleWorkspacePanZoomUpdate,
          handleWorkspacePanZoomEnd: _workspaceRuntime.workspaceWindowController.handleWorkspacePanZoomEnd,
          toggleExpose: _foundation.appUiController.toggleExpose,
          fitWorkspaceViewportToContent: _workspaceRuntime.workspaceWindowController.fitWorkspaceViewportToContent,
          confirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
          setWorkspaceViewport: _workspaceRuntime.workspaceViewportSessionController.setWorkspaceViewport,
        ),
      ),
    );
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
      foundation: _foundation,
      documents: _documents,
      mounted: () => mounted,
      seedEnvironment: buildSeedEnvironment,
      isRunningInWidgetTest: _isRunningInWidgetTest,
    );
    _documentPersistence.restoreEnvironment();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  AppRuntimeInputs _buildRuntimeInputs() {
    return AppRuntimeInputBuilder(
      stateStore: _stateStore,
      uiHandles: _uiHandles,
      context: () => context,
      mounted: () => mounted,
      commitStateChange: setState,
      showMessage: _showMessage,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      derivedState: () => _derivedState,
      foundation: () => _foundation,
      workspace: () => _workspaceRuntime,
      documentPersistence: () => _documentPersistence,
    ).build();
  }

  bool get _isRunningInWidgetTest {
    return Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  Widget build(BuildContext context) {
    final focusedWindow = _workspaceRuntime.workspaceWindowController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && _workspaceRuntime.workspaceController.expose.contains(focusedWindow.asset.id);

    return AppMenu(
      activeWorkspaceId: _state.environmentStoreState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: _state.workspaceWindowHistoryState.entries,
      showAboutSerenity: _feedback.showAboutSerenity,
      openSettings: _settings.openSettings,
      createEnvironment: _documents.documentCoordinator.createDocument,
      openEnvironment: _documents.documentCoordinator.openDocument,
      openAssets: _pickAndImportAssets,
      saveEnvironment: _documents.documentCoordinator.saveDocument,
      saveEnvironmentAs: _documents.documentCoordinator.saveDocumentAs,
      revealAssetInFinder: _foundation.platformBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceRuntime.environmentController.navigation.toggleSelectedWindow,
      fitWindowToContent: _workspaceRuntime.workspaceWindowController.fitWindowToContent,
      restorePreviousWindowZOrder: _workspaceRuntime.workspaceWindowController.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: _workspaceRuntime.workspaceVideoConversionController.convertVideoWindowToJpeg,
      closeWindow: _workspaceRuntime.workspaceWindowHistoryController.removeWindow,
      toggleExpose: _foundation.appUiController.toggleExpose,
      toggleWorkspaceOverview: _workspaceRuntime.environmentController.navigation.toggleOverview,
      createWorkspace: _workspaceRuntime.environmentController.management.create,
      switchToPreviousWorkspace: () => _workspaceRuntime.environmentController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceRuntime.environmentController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _workspaceRuntime.workspaceWindowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
      pauseAllVideos: _workspaceRuntime.workspaceWindowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _feedback.showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceRuntime.environmentController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _feedback.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceRuntime.environmentController.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _workspaceRuntime.workspaceWindowHistoryController.restoreRecentlyClosedWindow,
      child: Focus(
        focusNode: _uiHandles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _workspaceRuntime.workspaceShortcutController.onKeyEvent(event),
        child: Scaffold(body: SafeArea(top: false, child: _buildContent(context))),
      ),
    );
  }
}

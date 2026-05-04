import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime_config_builder.dart';
import 'package:serenity_viewer/src/app/app_owned_state.dart';
import 'package:serenity_viewer/src/app/app_view_state.dart';
import 'package:serenity_viewer/src/app/builders/app_menu_builder.dart';
import 'package:serenity_viewer/src/app/builders/app_screen_host_builder.dart';
import 'package:serenity_viewer/src/app/builders/app_screen_host_scope.dart';
import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/environment/document/document_persistence_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _ownedState = AppOwnedState();
  late final AppRuntime _runtime;
  late final AppFeedbackController _feedback;
  late final AppSettingsController _settings;
  late final DocumentPersistenceController _documentPersistence;

  AppStateServices get _state => _runtime.state;
  AppViewState get _viewState => AppViewState(_state);
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

  List<PlatformMenuItem> _buildMenus() {
    final focusedWindow = _workspaceRuntime.workspaceWindowController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && _workspaceRuntime.workspaceController.expose.contains(focusedWindow.asset.id);

    return AppMenuBuilder(
      showAboutSerenity: _feedback.showAboutSerenity,
      openSettings: _settings.openSettings,
      createEnvironment: _documents.documentCoordinator.createDocument,
      openEnvironment: _documents.documentCoordinator.openDocument,
      openAssets: _pickAndImportAssets,
      saveEnvironment: _documents.documentCoordinator.saveDocument,
      saveEnvironmentAs: _documents.documentCoordinator.saveDocumentAs,
      revealAssetInFinder: _foundation.platformBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceRuntime.environmentSession.navigation.toggleSelectedWindow,
      fitWindowToContent: _workspaceRuntime.workspaceWindowController.fitWindowToContent,
      restorePreviousWindowZOrder: _workspaceRuntime.workspaceWindowController.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: (windowId) =>
          _workspaceRuntime.workspaceVideoConversionController.convertVideoWindowToJpeg(windowId),
      closeWindow: _workspaceRuntime.workspaceWindowHistoryController.removeWindow,
      toggleExpose: _foundation.appUiController.toggleExpose,
      toggleWorkspaceOverview: _workspaceRuntime.environmentSession.navigation.toggleOverview,
      createWorkspace: _workspaceRuntime.environmentSession.management.create,
      switchToPreviousWorkspace: () => _workspaceRuntime.environmentSession.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceRuntime.environmentSession.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _workspaceRuntime.workspaceWindowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
      pauseAllVideos: _workspaceRuntime.workspaceWindowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _feedback.showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceRuntime.environmentSession.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _feedback.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceRuntime.environmentSession.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _workspaceRuntime.workspaceWindowHistoryController.restoreRecentlyClosedWindow,
    ).build(
      activeWorkspaceId: _state.environmentStoreState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: _state.workspaceWindowHistoryState.entries,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_state.environmentStoreState.isLoading || _state.environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AppScreenHostBuilder(
      state: AppScreenHostState(
        context: context,
        uiState: _state.appUiState,
        environment: _state.environmentStoreState.environment!,
        windowTitle: _viewState.windowTitle,
        workspaces: _viewState.workspaces,
        openWorkspaces: _viewState.openWorkspaces,
        activeWorkspace: _viewState.activeWorkspace,
        activeWorkspaceOrNull: _viewState.activeWorkspaceOrNull,
        selectedExposeWindowCount: _workspaceRuntime.workspaceController.expose.count(),
        windowInteractionState: _state.windowInteractionState,
        workspaceViewportState: _state.workspaceViewportState,
        appUiController: _foundation.appUiController,
        sharedVideoControllerPool: _foundation.sharedVideoControllerPool,
        environmentSession: _workspaceRuntime.environmentSession,
        workspaceLinksController: _workspaceRuntime.workspaceLinksController,
        thumbnailController: _workspaceRuntime.thumbnailController,
        windowHistoryController: _workspaceRuntime.workspaceWindowHistoryController,
        searchController: _state.uiHandles.searchController,
        tabScrollController: _state.uiHandles.tabScrollController,
      ),
      actions: AppScreenHostActions(
        commitStateChange: setState,
        importFiles: _workspaceRuntime.workspaceMediaImportController.importFiles,
        handleOptionGestureHover: _workspaceRuntime.workspaceWindowController.handleOptionGestureHover,
        handleWorkspacePanZoomStart: _workspaceRuntime.workspaceWindowController.handleWorkspacePanZoomStart,
        handleWorkspacePanZoomUpdate: _workspaceRuntime.workspaceWindowController.handleWorkspacePanZoomUpdate,
        handleWorkspacePanZoomEnd: _workspaceRuntime.workspaceWindowController.handleWorkspacePanZoomEnd,
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
        toggleExpose: _foundation.appUiController.toggleExpose,
        setPinnedHoverWindow: _workspaceRuntime.workspaceWindowController.setPinnedHoverWindow,
        clearPinnedHoverWindow: _workspaceRuntime.workspaceWindowController.clearPinnedHoverWindow,
        flashWindow: (windowId) => _workspaceRuntime.workspaceWindowController.flashWindow(windowId, mounted: mounted),
        setActiveGestureWindow: _workspaceRuntime.workspaceWindowController.setActiveGestureWindow,
        fitWorkspaceViewportToContent: _workspaceRuntime.workspaceWindowController.fitWorkspaceViewportToContent,
        confirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
        setWorkspaceViewport: _workspaceRuntime.workspaceViewportSessionController.setWorkspaceViewport,
        revealAssetInFinder: _foundation.platformBridge.revealAssetInFinder,
      ),
    ).build();
  }

  @override
  void initState() {
    super.initState();
    _runtime = AppRuntime.create(_buildRuntimeConfig());
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

  AppRuntimeConfig _buildRuntimeConfig() {
    return AppRuntimeConfigBuilder(
      ownedState: _ownedState,
      context: () => context,
      mounted: () => mounted,
      commitStateChange: setState,
      showMessage: _showMessage,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      viewState: () => _viewState,
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
    return PlatformMenuBar(
      menus: _buildMenus(),
      child: Focus(
        focusNode: _state.uiHandles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _workspaceRuntime.environmentSession.shortcuts.onKeyEvent(event),
        child: Scaffold(body: SafeArea(top: false, child: _buildContent(context))),
      ),
    );
  }
}

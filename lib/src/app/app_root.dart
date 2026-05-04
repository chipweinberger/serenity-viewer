import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/assembly/app_runtime.dart';
import 'package:serenity_viewer/src/app/assembly/app_runtime_config_builder.dart';
import 'package:serenity_viewer/src/app/app_dependencies.dart';
import 'package:serenity_viewer/src/app/app_actions.dart';
import 'package:serenity_viewer/src/app/app_derived_state.dart';
import 'package:serenity_viewer/src/app/app_persistence_controller.dart';
import 'package:serenity_viewer/src/app/builders/content_builder.dart';
import 'package:serenity_viewer/src/app/builders/content_scope.dart';
import 'package:serenity_viewer/src/app/builders/menu_builder.dart';
import 'package:serenity_viewer/src/app/seed_environment.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _dependencies = AppDependencies();
  late final AppRuntime _runtime;
  late final AppActions _controller;
  late final AppPersistenceController _persistence;

  AppStateServices get _state => _runtime.state;
  AppDerivedState get _derived => AppDerivedState(_state);
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
      _controller.feedback.showMessage('There are no image or video windows to collate.');
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

    return MenuBuilder(
      showAboutSerenity: _controller.feedback.showAboutSerenity,
      openSettings: _controller.feedback.openSettings,
      createEnvironment: _documents.documentCoordinator.createDocument,
      openEnvironment: _documents.documentCoordinator.openDocument,
      openAssets: _pickAndImportAssets,
      saveEnvironment: _documents.documentCoordinator.saveDocument,
      saveEnvironmentAs: _documents.documentCoordinator.saveDocumentAs,
      revealAssetInFinder: _foundation.mediaBridge.revealAssetInFinder,
      toggleWindowSelected: _workspaceRuntime.environmentController.navigation.toggleSelectedWindow,
      fitWindowToContent: _workspaceRuntime.workspaceWindowController.fitWindowToContent,
      restorePreviousWindowZOrder: _workspaceRuntime.workspaceWindowController.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: (windowId) =>
          _workspaceRuntime.videoConversionCoordinator.convertVideoWindowToJpeg(windowId),
      closeWindow: _workspaceRuntime.workspaceWindowHistoryController.removeWindow,
      toggleExpose: _controller.appUi.toggleExpose,
      toggleWorkspaceOverview: _workspaceRuntime.environmentController.navigation.toggleOverview,
      createWorkspace: _workspaceRuntime.environmentController.management.create,
      switchToPreviousWorkspace: () => _workspaceRuntime.environmentController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => _workspaceRuntime.environmentController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: _workspaceRuntime.workspaceWindowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
      pauseAllVideos: _workspaceRuntime.workspaceWindowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => _controller.feedback.showMessage('There is no workspace to rename.'),
      renameWorkspace: _workspaceRuntime.environmentController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => _controller.feedback.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: _workspaceRuntime.environmentController.management.confirmDeleteWorkspace,
      restoreRecentlyClosedWindow: _workspaceRuntime.workspaceWindowHistoryController.restoreRecentlyClosedWindow,
    ).build(
      activeWorkspaceId: _state.environmentStoreState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: _state.recentlyClosedWindowsState.entries,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_state.environmentStoreState.isLoading || _state.environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ContentBuilder(
      state: ContentState(
        context: context,
        uiState: _state.appUiState,
        environment: _state.environmentStoreState.environment!,
        windowTitle: _derived.windowTitle,
        workspaces: _derived.workspaces,
        openWorkspaces: _derived.openWorkspaces,
        activeWorkspace: _derived.activeWorkspace,
        activeWorkspaceOrNull: _derived.activeWorkspaceOrNull,
        selectedExposeWindowCount: _workspaceRuntime.workspaceController.expose.count(),
        windowInteractionState: _state.windowInteractionState,
        workspaceViewportState: _state.workspaceViewportState,
        appUiController: _foundation.appUiController,
        mediaBridge: _foundation.mediaBridge,
        environmentController: _workspaceRuntime.environmentController,
        workspaceLinksController: _workspaceRuntime.workspaceLinksController,
        thumbnailController: _workspaceRuntime.thumbnailController,
        windowHistoryController: _workspaceRuntime.workspaceWindowHistoryController,
        searchController: _state.handles.searchController,
        tabScrollController: _state.handles.tabScrollController,
      ),
      actions: ContentActions(
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
        toggleExpose: _controller.appUi.toggleExpose,
        setPinnedHoverWindow: _workspaceRuntime.workspaceWindowController.setPinnedHoverWindow,
        clearPinnedHoverWindow: _workspaceRuntime.workspaceWindowController.clearPinnedHoverWindow,
        flashWindow: (windowId) => _workspaceRuntime.workspaceWindowController.flashWindow(windowId, mounted: mounted),
        setActiveGestureWindow: _workspaceRuntime.workspaceWindowController.setActiveGestureWindow,
        fitWorkspaceViewportToContent: _workspaceRuntime.workspaceWindowController.fitWorkspaceViewportToContent,
        confirmCollateWorkspaceWindows: _confirmCollateWorkspaceWindows,
        setWorkspaceViewport: _workspaceRuntime.workspaceViewportSessionController.setWorkspaceViewport,
      ),
    ).build();
  }

  @override
  void initState() {
    super.initState();
    _runtime = AppRuntime.create(_buildRuntimeConfig());
    _controller = AppActions(
      context: () => context,
      state: _state,
      foundation: _foundation,
      workspace: _workspaceRuntime,
    );
    _persistence = AppPersistenceController(
      state: _state,
      foundation: _foundation,
      documents: _documents,
      mounted: () => mounted,
      seedEnvironment: buildSeedEnvironment,
      isRunningInWidgetTest: _isRunningInWidgetTest,
    );
    _persistence.restoreEnvironment();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  AppRuntimeConfig _buildRuntimeConfig() {
    return AppRuntimeConfigBuilder(
      dependencies: _dependencies,
      context: () => context,
      mounted: () => mounted,
      commitStateChange: setState,
      showMessage: _showMessage,
      isRunningInWidgetTest: _isRunningInWidgetTest,
      derivedState: () => _derived,
      foundation: () => _foundation,
      controller: () => _controller,
      persistence: () => _persistence,
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
        focusNode: _state.handles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _workspaceRuntime.environmentController.shortcuts.onKeyEvent(event),
        child: Scaffold(body: SafeArea(top: false, child: _buildContent(context))),
      ),
    );
  }
}

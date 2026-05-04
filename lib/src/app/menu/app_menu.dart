import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_entry.dart';
import 'package:serenity_viewer/src/environment/history/environment_window_history_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/app_settings_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

class _MenuState {
  const _MenuState({
    required this.activeWorkspaceId,
    required this.focusedWindow,
    required this.focusedWindowIsSelected,
    required this.recentlyClosedWindows,
  });

  final String? activeWorkspaceId;
  final Window? focusedWindow;
  final bool focusedWindowIsSelected;
  final List<EnvironmentWindowHistoryEntry> recentlyClosedWindows;
}

class AppMenu extends StatelessWidget {
  const AppMenu({super.key, required this.child});

  final Widget child;

  ({
    String? activeWorkspaceId,
    List<EnvironmentWindowHistoryEntry> recentlyClosedWindows,
    Set<String> selectedExposeWindowIds,
  })
  _watchState(BuildContext context) {
    return (
      activeWorkspaceId: context.select((EnvironmentStoreState state) => state.environment?.activeWorkspaceId),
      selectedExposeWindowIds: context.select(
        (WindowInteractionState state) => Set<String>.of(state.selectedExposeWindowIds),
      ),
      recentlyClosedWindows: context.select(
        (EnvironmentWindowHistoryState state) => List<EnvironmentWindowHistoryEntry>.of(state.entries),
      ),
    );
  }

  ({
    AppUiController appUiController,
    PlatformBridge platformBridge,
    DocumentCoordinator documentCoordinator,
    WorkspaceController workspaceController,
    EnvironmentController environmentController,
    AppFeedbackController feedback,
    AppSettingsController settings,
  })
  _readDependencies(BuildContext context) {
    return (
      appUiController: context.read<AppUiController>(),
      platformBridge: context.read<PlatformBridge>(),
      documentCoordinator: context.read<DocumentCoordinator>(),
      workspaceController: context.read<WorkspaceController>(),
      environmentController: context.read<EnvironmentController>(),
      feedback: context.read<AppFeedbackController>(),
      settings: context.read<AppSettingsController>(),
    );
  }

  _MenuState _buildState({
    required String? activeWorkspaceId,
    required Set<String> selectedExposeWindowIds,
    required List<EnvironmentWindowHistoryEntry> recentlyClosedWindows,
    required WorkspaceController workspaceController,
  }) {
    final focusedWindow = workspaceController.window.focusedWindowOrNull();
    final focusedWindowIsSelected = focusedWindow != null && selectedExposeWindowIds.contains(focusedWindow.asset.id);

    return _MenuState(
      activeWorkspaceId: activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: recentlyClosedWindows,
    );
  }

  List<PlatformMenuItem> _buildHistoryMenuItems({
    required _MenuState state,
    required EnvironmentController environmentController,
  }) {
    final recentlyClosedItems = state.recentlyClosedWindows.take(8).map((entry) {
      return PlatformMenuItem(
        label: 'Restore ${entry.window.asset.filename}',
        onSelected: () => environmentController.history.restoreRecentlyClosedWindow(entry),
      );
    }).toList();

    return [
      PlatformMenuItem(
        label: 'Restore Last Closed',
        onSelected: state.recentlyClosedWindows.isEmpty
            ? null
            : environmentController.history.restoreRecentlyClosedWindow,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true),
      ),
      ...recentlyClosedItems,
    ];
  }

  List<PlatformMenuItem> _buildAppMenuItems({
    required AppFeedbackController feedback,
    required AppSettingsController settings,
  }) {
    return [
      PlatformMenuItem(label: 'About Serenity', onSelected: feedback.showAboutSerenity),
      PlatformMenuItem(
        label: 'Settings',
        onSelected: () => unawaited(settings.openSettings()),
        shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true),
      ),
      PlatformMenuItem(
        label: 'Quit Serenity',
        onSelected: _quitApplication,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
      ),
    ];
  }

  List<PlatformMenuItem> _buildFileMenuItems({
    required DocumentCoordinator documentCoordinator,
    required WorkspaceController workspaceController,
  }) {
    return [
      PlatformMenuItem(
        label: 'New Environment…',
        onSelected: () => unawaited(documentCoordinator.createDocument()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Open Environment…',
        onSelected: () => unawaited(documentCoordinator.openDocument()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Open Assets…',
        onSelected: () => unawaited(workspaceController.media.pickAndImportAssets()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
      ),
      PlatformMenuItem(
        label: 'Open Folder…',
        onSelected: () => unawaited(workspaceController.media.pickAndImportFolder()),
      ),
      PlatformMenuItem(
        label: 'Save',
        onSelected: () => unawaited(documentCoordinator.saveDocument()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
      ),
      PlatformMenuItem(
        label: 'Save As…',
        onSelected: () => unawaited(documentCoordinator.saveDocumentAs()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
      ),
    ];
  }

  List<PlatformMenuItem> _buildAssetMenuItems({
    required _MenuState state,
    required PlatformBridge platformBridge,
    required WorkspaceController workspaceController,
  }) {
    final focusedWindow = state.focusedWindow;
    final focusedVideoWindow = focusedWindow?.asset.type == AssetType.video ? focusedWindow : null;
    final focusedWindowLabel = focusedWindow == null
        ? 'No Asset Selected'
        : _middleTruncatedLabel(focusedWindow.asset.filename);

    return [
      PlatformMenuItem(label: focusedWindowLabel, onSelected: null),
      PlatformMenuItemGroup(
        members: [
          PlatformMenuItem(
            label: 'Reveal in Finder',
            onSelected: focusedWindow == null
                ? null
                : () => unawaited(platformBridge.revealAssetInFinder(focusedWindow.asset)),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Convert to JPEG',
            onSelected: focusedVideoWindow == null
                ? null
                : () => unawaited(workspaceController.media.convertVideoWindowToJpeg(focusedVideoWindow.asset.id)),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyJ, meta: true, shift: true),
          ),
        ],
      ),
    ];
  }

  List<PlatformMenuItem> _buildWindowMenuItems({
    required _MenuState state,
    required EnvironmentController environmentController,
    required WorkspaceController workspaceController,
  }) {
    final focusedWindow = state.focusedWindow;

    return [
      PlatformMenuItemGroup(
        members: [
          PlatformMenuItem(
            label: state.focusedWindowIsSelected ? 'Deselect' : 'Select',
            onSelected: focusedWindow == null
                ? null
                : () => environmentController.navigation.toggleSelectedWindow(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
          ),
          PlatformMenuItem(
            label: 'Fit to Content',
            onSelected: focusedWindow == null
                ? null
                : () => workspaceController.window.fitWindowToContent(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
          ),
          PlatformMenuItem(
            label: 'Send Back',
            onSelected: focusedWindow == null
                ? null
                : () => workspaceController.window.restorePreviousWindowZOrder(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Close',
            onSelected: focusedWindow == null || state.activeWorkspaceId == null
                ? null
                : () => environmentController.history.removeWindow(state.activeWorkspaceId!, focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.backspace, meta: true),
          ),
        ],
      ),
    ];
  }

  List<PlatformMenuItem> _buildViewMenuItems({
    required AppUiController appUiController,
    required EnvironmentController environmentController,
  }) {
    return [
      PlatformMenuItem(
        label: 'Expose',
        onSelected: appUiController.toggleExpose,
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp),
      ),
      PlatformMenuItem(
        label: 'View All',
        onSelected: environmentController.navigation.toggleOverview,
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowDown),
      ),
    ];
  }

  List<PlatformMenuItem> _buildWorkspaceMenuItems({
    required _MenuState state,
    required EnvironmentController environmentController,
    required WorkspaceController workspaceController,
    required AppFeedbackController feedback,
  }) {
    return [
      PlatformMenuItem(
        label: 'New',
        onSelected: environmentController.management.create,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true),
      ),
      PlatformMenuItem(
        label: 'Previous',
        onSelected: () => environmentController.navigation.switchWorkspace(-1),
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowLeft),
      ),
      PlatformMenuItem(
        label: 'Next',
        onSelected: () => environmentController.navigation.switchWorkspace(1),
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowRight),
      ),
      PlatformMenuItem(
        label: 'Fit to Assets',
        onSelected: workspaceController.viewport.fitWorkspaceViewportToContent,
        shortcut: const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
      ),
      PlatformMenuItem(
        label: 'Collate',
        onSelected: state.activeWorkspaceId == null
            ? null
            : () => unawaited(workspaceController.layout.confirmCollateWorkspaceWindows()),
        shortcut: const SingleActivator(LogicalKeyboardKey.digit3, meta: true),
      ),
      PlatformMenuItem(
        label: 'Pause All',
        onSelected: workspaceController.playback.pauseAllVideos,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Rename…',
        onSelected: state.activeWorkspaceId == null
            ? () => feedback.showMessage('There is no workspace to rename.')
            : () => unawaited(environmentController.management.renameWorkspace(state.activeWorkspaceId!)),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyW, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Delete…',
        onSelected: state.activeWorkspaceId == null
            ? () => feedback.showMessage('There is no workspace to delete.')
            : () => unawaited(environmentController.management.confirmDeleteWorkspace(state.activeWorkspaceId!)),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true),
      ),
    ];
  }

  List<PlatformMenuItem> _buildMenus({
    required _MenuState state,
    required ({
      AppUiController appUiController,
      PlatformBridge platformBridge,
      DocumentCoordinator documentCoordinator,
      WorkspaceController workspaceController,
      EnvironmentController environmentController,
      AppFeedbackController feedback,
      AppSettingsController settings,
    })
    dependencies,
  }) {
    return [
      PlatformMenu(
        label: 'Serenity',
        menus: _buildAppMenuItems(feedback: dependencies.feedback, settings: dependencies.settings),
      ),
      PlatformMenu(
        label: 'File',
        menus: _buildFileMenuItems(
          documentCoordinator: dependencies.documentCoordinator,
          workspaceController: dependencies.workspaceController,
        ),
      ),
      PlatformMenu(
        label: 'Asset',
        menus: _buildAssetMenuItems(
          state: state,
          platformBridge: dependencies.platformBridge,
          workspaceController: dependencies.workspaceController,
        ),
      ),
      PlatformMenu(
        label: 'Window',
        menus: _buildWindowMenuItems(
          state: state,
          environmentController: dependencies.environmentController,
          workspaceController: dependencies.workspaceController,
        ),
      ),
      PlatformMenu(
        label: 'Workspace',
        menus: _buildWorkspaceMenuItems(
          state: state,
          environmentController: dependencies.environmentController,
          workspaceController: dependencies.workspaceController,
          feedback: dependencies.feedback,
        ),
      ),
      PlatformMenu(
        label: 'View',
        menus: _buildViewMenuItems(
          appUiController: dependencies.appUiController,
          environmentController: dependencies.environmentController,
        ),
      ),
      PlatformMenu(
        label: 'History',
        menus: _buildHistoryMenuItems(state: state, environmentController: dependencies.environmentController),
      ),
    ];
  }

  static String _middleTruncatedLabel(String value, {int maxLength = 42}) {
    if (value.length <= maxLength) {
      return value;
    }

    final available = maxLength - 1;
    final leadingLength = (available / 2).ceil();
    final trailingLength = (available / 2).floor();
    return '${value.substring(0, leadingLength)}…${value.substring(value.length - trailingLength)}';
  }

  static void _quitApplication() {
    unawaited(ServicesBinding.instance.exitApplication(ui.AppExitType.cancelable));
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final dependencies = _readDependencies(context);

    final menuState = _buildState(
      activeWorkspaceId: state.activeWorkspaceId,
      selectedExposeWindowIds: state.selectedExposeWindowIds,
      recentlyClosedWindows: state.recentlyClosedWindows,
      workspaceController: dependencies.workspaceController,
    );

    return PlatformMenuBar(
      menus: _buildMenus(state: menuState, dependencies: dependencies),
      child: child,
    );
  }
}

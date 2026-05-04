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
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_asset_picker_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_collate_controller.dart';
import 'package:serenity_viewer/src/workspace/actions/workspace_video_conversion_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_entry.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_state.dart';

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
  final List<WorkspaceWindowHistoryEntry> recentlyClosedWindows;
}

class AppMenu extends StatelessWidget {
  const AppMenu({super.key, required this.child});

  final Widget child;

  ({
    String? activeWorkspaceId,
    List<WorkspaceWindowHistoryEntry> recentlyClosedWindows,
    Set<String> selectedExposeWindowIds,
  })
  _watchState(BuildContext context) {
    return (
      activeWorkspaceId: context.select((EnvironmentStoreState state) => state.environment?.activeWorkspaceId),
      selectedExposeWindowIds: context.select(
        (WindowInteractionState state) => Set<String>.of(state.selectedExposeWindowIds),
      ),
      recentlyClosedWindows: context.select(
        (WorkspaceWindowHistoryState state) => List<WorkspaceWindowHistoryEntry>.of(state.entries),
      ),
    );
  }

  ({
    AppUiController appUiController,
    PlatformBridge platformBridge,
    DocumentCoordinator documentCoordinator,
    WorkspaceWindowController workspaceWindowController,
    EnvironmentController environmentController,
    WorkspaceVideoConversionController workspaceVideoConversionController,
    WorkspaceWindowHistoryController workspaceWindowHistoryController,
    WorkspaceCollateController workspaceCollateController,
    WorkspaceAssetPickerController workspaceAssetPickerController,
    AppFeedbackController feedback,
    AppSettingsController settings,
  })
  _readDependencies(BuildContext context) {
    return (
      appUiController: context.read<AppUiController>(),
      platformBridge: context.read<PlatformBridge>(),
      documentCoordinator: context.read<DocumentCoordinator>(),
      workspaceWindowController: context.read<WorkspaceWindowController>(),
      environmentController: context.read<EnvironmentController>(),
      workspaceVideoConversionController: context.read<WorkspaceVideoConversionController>(),
      workspaceWindowHistoryController: context.read<WorkspaceWindowHistoryController>(),
      workspaceCollateController: context.read<WorkspaceCollateController>(),
      workspaceAssetPickerController: context.read<WorkspaceAssetPickerController>(),
      feedback: context.read<AppFeedbackController>(),
      settings: context.read<AppSettingsController>(),
    );
  }

  _MenuState _buildState({
    required String? activeWorkspaceId,
    required Set<String> selectedExposeWindowIds,
    required List<WorkspaceWindowHistoryEntry> recentlyClosedWindows,
    required WorkspaceWindowController workspaceWindowController,
  }) {
    final focusedWindow = workspaceWindowController.focusedWindowOrNull();
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
    required WorkspaceWindowHistoryController workspaceWindowHistoryController,
  }) {
    final recentlyClosedItems = state.recentlyClosedWindows.take(8).map((entry) {
      return PlatformMenuItem(
        label: 'Restore ${entry.window.asset.filename}',
        onSelected: () => workspaceWindowHistoryController.restoreRecentlyClosedWindow(entry),
      );
    }).toList();

    return [
      PlatformMenuItem(
        label: 'Restore Last Closed',
        onSelected: state.recentlyClosedWindows.isEmpty
            ? null
            : workspaceWindowHistoryController.restoreRecentlyClosedWindow,
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
    required WorkspaceAssetPickerController workspaceAssetPickerController,
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
        onSelected: () => unawaited(workspaceAssetPickerController.pickAndImportAssets()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
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
    required WorkspaceVideoConversionController workspaceVideoConversionController,
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
                : () => unawaited(
                    workspaceVideoConversionController.convertVideoWindowToJpeg(focusedVideoWindow.asset.id),
                  ),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyJ, meta: true, shift: true),
          ),
        ],
      ),
    ];
  }

  List<PlatformMenuItem> _buildWindowMenuItems({
    required _MenuState state,
    required EnvironmentController environmentController,
    required WorkspaceWindowController workspaceWindowController,
    required WorkspaceWindowHistoryController workspaceWindowHistoryController,
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
                : () => workspaceWindowController.fitWindowToContent(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
          ),
          PlatformMenuItem(
            label: 'Send Back',
            onSelected: focusedWindow == null
                ? null
                : () => workspaceWindowController.restorePreviousWindowZOrder(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Close',
            onSelected: focusedWindow == null || state.activeWorkspaceId == null
                ? null
                : () => workspaceWindowHistoryController.removeWindow(state.activeWorkspaceId!, focusedWindow.asset.id),
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
    required WorkspaceWindowController workspaceWindowController,
    required WorkspaceCollateController workspaceCollateController,
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
        onSelected: workspaceWindowController.fitWorkspaceViewportToContent,
        shortcut: const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
      ),
      PlatformMenuItem(
        label: 'Collate',
        onSelected: state.activeWorkspaceId == null
            ? null
            : () => unawaited(workspaceCollateController.confirmCollateWorkspaceWindows()),
        shortcut: const SingleActivator(LogicalKeyboardKey.digit3, meta: true),
      ),
      PlatformMenuItem(
        label: 'Pause All',
        onSelected: workspaceWindowController.pauseAllVideos,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Rename…',
        onSelected: state.activeWorkspaceId == null
            ? () => feedback.showMessage('There is no workspace to rename.')
            : () => unawaited(environmentController.management.renameWorkspace(state.activeWorkspaceId!)),
      ),
      PlatformMenuItem(
        label: 'Delete…',
        onSelected: state.activeWorkspaceId == null
            ? () => feedback.showMessage('There is no workspace to delete.')
            : () => unawaited(environmentController.management.confirmDeleteWorkspace(state.activeWorkspaceId!)),
      ),
    ];
  }

  List<PlatformMenuItem> _buildMenus({
    required _MenuState state,
    required ({
      AppUiController appUiController,
      PlatformBridge platformBridge,
      DocumentCoordinator documentCoordinator,
      WorkspaceWindowController workspaceWindowController,
      EnvironmentController environmentController,
      WorkspaceVideoConversionController workspaceVideoConversionController,
      WorkspaceWindowHistoryController workspaceWindowHistoryController,
      WorkspaceCollateController workspaceCollateController,
      WorkspaceAssetPickerController workspaceAssetPickerController,
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
          workspaceAssetPickerController: dependencies.workspaceAssetPickerController,
        ),
      ),
      PlatformMenu(
        label: 'Asset',
        menus: _buildAssetMenuItems(
          state: state,
          platformBridge: dependencies.platformBridge,
          workspaceVideoConversionController: dependencies.workspaceVideoConversionController,
        ),
      ),
      PlatformMenu(
        label: 'Window',
        menus: _buildWindowMenuItems(
          state: state,
          environmentController: dependencies.environmentController,
          workspaceWindowController: dependencies.workspaceWindowController,
          workspaceWindowHistoryController: dependencies.workspaceWindowHistoryController,
        ),
      ),
      PlatformMenu(
        label: 'Workspace',
        menus: _buildWorkspaceMenuItems(
          state: state,
          environmentController: dependencies.environmentController,
          workspaceWindowController: dependencies.workspaceWindowController,
          workspaceCollateController: dependencies.workspaceCollateController,
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
        menus: _buildHistoryMenuItems(
          state: state,
          workspaceWindowHistoryController: dependencies.workspaceWindowHistoryController,
        ),
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
      workspaceWindowController: dependencies.workspaceWindowController,
    );

    return PlatformMenuBar(
      menus: _buildMenus(state: menuState, dependencies: dependencies),
      child: child,
    );
  }
}

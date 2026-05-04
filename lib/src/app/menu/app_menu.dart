import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
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

class _AppActions {
  const _AppActions({required this.showAboutSerenity, required this.openSettings});

  final VoidCallback showAboutSerenity;
  final Future<void> Function() openSettings;
}

class _FileActions {
  const _FileActions({
    required this.createEnvironment,
    required this.openEnvironment,
    required this.openAssets,
    required this.saveEnvironment,
    required this.saveEnvironmentAs,
  });

  final Future<void> Function() createEnvironment;
  final Future<void> Function() openEnvironment;
  final Future<void> Function() openAssets;
  final Future<void> Function() saveEnvironment;
  final Future<void> Function() saveEnvironmentAs;
}

class _AssetActions {
  const _AssetActions({
    required this.revealAssetInFinder,
    required this.convertVideoWindowToJpeg,
  });

  final Future<void> Function(Asset asset) revealAssetInFinder;
  final Future<void> Function(String windowId) convertVideoWindowToJpeg;
}

class _WindowActions {
  const _WindowActions({
    required this.toggleWindowSelected,
    required this.fitWindowToContent,
    required this.restorePreviousWindowZOrder,
    required this.closeWindow,
  });

  final ValueChanged<String> toggleWindowSelected;
  final ValueChanged<String> fitWindowToContent;
  final ValueChanged<String> restorePreviousWindowZOrder;
  final void Function(String workspaceId, String windowId) closeWindow;
}

class _WorkspaceActions {
  const _WorkspaceActions({
    required this.toggleExpose,
    required this.toggleWorkspaceOverview,
    required this.createWorkspace,
    required this.switchToPreviousWorkspace,
    required this.switchToNextWorkspace,
    required this.fitWorkspaceViewportToContent,
    required this.confirmCollateWorkspaceWindows,
    required this.pauseAllVideos,
    required this.showNoWorkspaceToRenameMessage,
    required this.renameWorkspace,
    required this.showNoWorkspaceToDeleteMessage,
    required this.confirmDeleteWorkspace,
  });

  final VoidCallback toggleExpose;
  final VoidCallback toggleWorkspaceOverview;
  final VoidCallback createWorkspace;
  final VoidCallback switchToPreviousWorkspace;
  final VoidCallback switchToNextWorkspace;
  final VoidCallback fitWorkspaceViewportToContent;
  final Future<void> Function() confirmCollateWorkspaceWindows;
  final VoidCallback pauseAllVideos;
  final VoidCallback showNoWorkspaceToRenameMessage;
  final Future<void> Function(String workspaceId) renameWorkspace;
  final VoidCallback showNoWorkspaceToDeleteMessage;
  final Future<void> Function(String workspaceId) confirmDeleteWorkspace;
}

class _HistoryActions {
  const _HistoryActions({required this.restoreRecentlyClosedWindow});

  final void Function([WorkspaceWindowHistoryEntry? entry]) restoreRecentlyClosedWindow;
}

class AppMenu extends StatelessWidget {
  const AppMenu({super.key, required this.child});

  final Widget child;

  _MenuState _buildState({
    required EnvironmentStoreState environmentStoreState,
    required WindowInteractionState windowInteractionState,
    required WorkspaceWindowHistoryState workspaceWindowHistoryState,
    required WorkspaceWindowController workspaceWindowController,
  }) {
    final focusedWindow = workspaceWindowController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && windowInteractionState.selectedExposeWindowIds.contains(focusedWindow.asset.id);

    return _MenuState(
      activeWorkspaceId: environmentStoreState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: workspaceWindowHistoryState.entries,
    );
  }

  _AppActions _buildAppActions({
    required AppFeedbackController feedback,
    required AppSettingsController settings,
  }) {
    return _AppActions(showAboutSerenity: feedback.showAboutSerenity, openSettings: settings.openSettings);
  }

  _FileActions _buildFileActions({
    required DocumentCoordinator documentCoordinator,
    required WorkspaceAssetPickerController workspaceAssetPickerController,
  }) {
    return _FileActions(
      createEnvironment: documentCoordinator.createDocument,
      openEnvironment: documentCoordinator.openDocument,
      openAssets: workspaceAssetPickerController.pickAndImportAssets,
      saveEnvironment: documentCoordinator.saveDocument,
      saveEnvironmentAs: documentCoordinator.saveDocumentAs,
    );
  }

  _WindowActions _buildWindowActions({
    required EnvironmentController environmentController,
    required WorkspaceWindowController workspaceWindowController,
    required WorkspaceWindowHistoryController workspaceWindowHistoryController,
  }) {
    return _WindowActions(
      toggleWindowSelected: environmentController.navigation.toggleSelectedWindow,
      fitWindowToContent: workspaceWindowController.fitWindowToContent,
      restorePreviousWindowZOrder: workspaceWindowController.restorePreviousWindowZOrder,
      closeWindow: workspaceWindowHistoryController.removeWindow,
    );
  }

  _AssetActions _buildAssetActions({
    required PlatformBridge platformBridge,
    required WorkspaceVideoConversionController workspaceVideoConversionController,
  }) {
    return _AssetActions(
      revealAssetInFinder: platformBridge.revealAssetInFinder,
      convertVideoWindowToJpeg: workspaceVideoConversionController.convertVideoWindowToJpeg,
    );
  }

  _WorkspaceActions _buildWorkspaceActions({
    required AppUiController appUiController,
    required EnvironmentController environmentController,
    required WorkspaceWindowController workspaceWindowController,
    required WorkspaceCollateController workspaceCollateController,
    required AppFeedbackController feedback,
  }) {
    return _WorkspaceActions(
      toggleExpose: appUiController.toggleExpose,
      toggleWorkspaceOverview: environmentController.navigation.toggleOverview,
      createWorkspace: environmentController.management.create,
      switchToPreviousWorkspace: () => environmentController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => environmentController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: workspaceWindowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: workspaceCollateController.confirmCollateWorkspaceWindows,
      pauseAllVideos: workspaceWindowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => feedback.showMessage('There is no workspace to rename.'),
      renameWorkspace: environmentController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => feedback.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: environmentController.management.confirmDeleteWorkspace,
    );
  }

  _HistoryActions _buildHistoryActionsController({
    required WorkspaceWindowHistoryController workspaceWindowHistoryController,
  }) {
    return _HistoryActions(
      restoreRecentlyClosedWindow: workspaceWindowHistoryController.restoreRecentlyClosedWindow,
    );
  }

  List<PlatformMenuItem> _buildHistoryActions({
    required _MenuState state,
    required _HistoryActions window,
  }) {
    final recentlyClosedItems = state.recentlyClosedWindows.take(8).map((entry) {
      return PlatformMenuItem(
        label: 'Restore ${entry.window.asset.filename}',
        onSelected: () => window.restoreRecentlyClosedWindow(entry),
      );
    }).toList();

    return [
      PlatformMenuItem(
        label: 'Restore Last Closed',
        onSelected: state.recentlyClosedWindows.isEmpty ? null : window.restoreRecentlyClosedWindow,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true),
      ),
      ...recentlyClosedItems,
    ];
  }

  List<PlatformMenuItem> _buildAppMenuItems({required _AppActions app}) {
    return [
      PlatformMenuItem(label: 'About Serenity', onSelected: app.showAboutSerenity),
      PlatformMenuItem(
        label: 'Settings',
        onSelected: () => unawaited(app.openSettings()),
        shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true),
      ),
      PlatformMenuItem(
        label: 'Quit Serenity',
        onSelected: _quitApplication,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
      ),
    ];
  }

  List<PlatformMenuItem> _buildFileMenuItems({required _FileActions file}) {
    return [
      PlatformMenuItem(
        label: 'New Environment…',
        onSelected: () => unawaited(file.createEnvironment()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Open Environment…',
        onSelected: () => unawaited(file.openEnvironment()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Open Assets…',
        onSelected: () => unawaited(file.openAssets()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
      ),
      PlatformMenuItem(
        label: 'Save',
        onSelected: () => unawaited(file.saveEnvironment()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
      ),
      PlatformMenuItem(
        label: 'Save As…',
        onSelected: () => unawaited(file.saveEnvironmentAs()),
        shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
      ),
    ];
  }

  List<PlatformMenuItem> _buildWindowMenuItems({
    required _MenuState state,
    required _AssetActions asset,
    required _WindowActions window,
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
            onSelected: focusedWindow == null ? null : () => unawaited(asset.revealAssetInFinder(focusedWindow.asset)),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: state.focusedWindowIsSelected ? 'Deselect' : 'Select',
            onSelected: focusedWindow == null ? null : () => window.toggleWindowSelected(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
          ),
          PlatformMenuItem(
            label: 'Fit to Content',
            onSelected: focusedWindow == null ? null : () => window.fitWindowToContent(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
          ),
          PlatformMenuItem(
            label: 'Send Back',
            onSelected:
                focusedWindow == null ? null : () => window.restorePreviousWindowZOrder(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Convert to JPEG',
            onSelected: focusedVideoWindow == null
                ? null
                : () => unawaited(asset.convertVideoWindowToJpeg(focusedVideoWindow.asset.id)),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyJ, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Close',
            onSelected: focusedWindow == null || state.activeWorkspaceId == null
                ? null
                : () => window.closeWindow(state.activeWorkspaceId!, focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.backspace, meta: true),
          ),
        ],
      ),
    ];
  }

  List<PlatformMenuItem> _buildViewMenuItems({required _WorkspaceActions workspace}) {
    return [
      PlatformMenuItem(
        label: 'Expose',
        onSelected: workspace.toggleExpose,
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp),
      ),
      PlatformMenuItem(
        label: 'View All',
        onSelected: workspace.toggleWorkspaceOverview,
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowDown),
      ),
    ];
  }

  List<PlatformMenuItem> _buildWorkspaceMenuItems({
    required _MenuState state,
    required _WorkspaceActions workspace,
  }) {
    return [
      PlatformMenuItem(
        label: 'New',
        onSelected: workspace.createWorkspace,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true),
      ),
      PlatformMenuItem(
        label: 'Previous',
        onSelected: workspace.switchToPreviousWorkspace,
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowLeft),
      ),
      PlatformMenuItem(
        label: 'Next',
        onSelected: workspace.switchToNextWorkspace,
        shortcut: const SingleActivator(LogicalKeyboardKey.arrowRight),
      ),
      PlatformMenuItem(
        label: 'Fit to Assets',
        onSelected: workspace.fitWorkspaceViewportToContent,
        shortcut: const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
      ),
      PlatformMenuItem(
        label: 'Collate',
        onSelected: state.activeWorkspaceId == null
            ? null
            : () => unawaited(workspace.confirmCollateWorkspaceWindows()),
        shortcut: const SingleActivator(LogicalKeyboardKey.digit3, meta: true),
      ),
      PlatformMenuItem(
        label: 'Pause All',
        onSelected: workspace.pauseAllVideos,
        shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
      ),
      PlatformMenuItem(
        label: 'Rename…',
        onSelected: state.activeWorkspaceId == null
            ? workspace.showNoWorkspaceToRenameMessage
            : () => unawaited(workspace.renameWorkspace(state.activeWorkspaceId!)),
      ),
      PlatformMenuItem(
        label: 'Delete…',
        onSelected: state.activeWorkspaceId == null
            ? workspace.showNoWorkspaceToDeleteMessage
            : () => unawaited(workspace.confirmDeleteWorkspace(state.activeWorkspaceId!)),
      ),
    ];
  }

  List<PlatformMenuItem> _buildMenus({
    required _MenuState state,
    required _AppActions app,
    required _FileActions file,
    required _AssetActions asset,
    required _WorkspaceActions workspace,
    required _HistoryActions history,
    required _WindowActions window,
  }) {
    return [
      PlatformMenu(label: 'Serenity', menus: _buildAppMenuItems(app: app)),
      PlatformMenu(label: 'File', menus: _buildFileMenuItems(file: file)),
      PlatformMenu(label: 'Window', menus: _buildWindowMenuItems(state: state, asset: asset, window: window)),
      PlatformMenu(label: 'View', menus: _buildViewMenuItems(workspace: workspace)),
      PlatformMenu(label: 'Workspace', menus: _buildWorkspaceMenuItems(state: state, workspace: workspace)),
      PlatformMenu(label: 'History', menus: _buildHistoryActions(state: state, window: history)),
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
    final environmentStoreState = context.watch<EnvironmentStoreState>();
    final windowInteractionState = context.watch<WindowInteractionState>();
    final workspaceWindowHistoryState = context.watch<WorkspaceWindowHistoryState>();
    final appUiController = context.read<AppUiController>();
    final platformBridge = context.read<PlatformBridge>();
    final documentCoordinator = context.read<DocumentCoordinator>();
    final workspaceWindowController = context.read<WorkspaceWindowController>();
    final environmentController = context.read<EnvironmentController>();
    final workspaceVideoConversionController = context.read<WorkspaceVideoConversionController>();
    final workspaceWindowHistoryController = context.read<WorkspaceWindowHistoryController>();
    final workspaceCollateController = context.read<WorkspaceCollateController>();
    final workspaceAssetPickerController = context.read<WorkspaceAssetPickerController>();
    final feedback = context.read<AppFeedbackController>();
    final settings = context.read<AppSettingsController>();

    final state = _buildState(
      environmentStoreState: environmentStoreState,
      windowInteractionState: windowInteractionState,
      workspaceWindowHistoryState: workspaceWindowHistoryState,
      workspaceWindowController: workspaceWindowController,
    );
    final app = _buildAppActions(feedback: feedback, settings: settings);
    final file = _buildFileActions(
      documentCoordinator: documentCoordinator,
      workspaceAssetPickerController: workspaceAssetPickerController,
    );
    final asset = _buildAssetActions(
      platformBridge: platformBridge,
      workspaceVideoConversionController: workspaceVideoConversionController,
    );
    final window = _buildWindowActions(
      environmentController: environmentController,
      workspaceWindowController: workspaceWindowController,
      workspaceWindowHistoryController: workspaceWindowHistoryController,
    );
    final workspace = _buildWorkspaceActions(
      appUiController: appUiController,
      environmentController: environmentController,
      workspaceWindowController: workspaceWindowController,
      workspaceCollateController: workspaceCollateController,
      feedback: feedback,
    );
    final history = _buildHistoryActionsController(workspaceWindowHistoryController: workspaceWindowHistoryController);

    return PlatformMenuBar(
      menus: _buildMenus(
        state: state,
        app: app,
        file: file,
        asset: asset,
        workspace: workspace,
        history: history,
        window: window,
      ),
      child: child,
    );
  }
}

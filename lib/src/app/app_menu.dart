import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/app/controllers/app_feedback_controller.dart';
import 'package:serenity_viewer/src/app/runtime/app_runtime_groups.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/behavior/app_settings_controller.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_entry.dart';

class AppMenuState {
  const AppMenuState({
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

class AppMenuAppActions {
  const AppMenuAppActions({required this.showAboutSerenity, required this.openSettings});

  final VoidCallback showAboutSerenity;
  final Future<void> Function() openSettings;
}

class AppMenuFileActions {
  const AppMenuFileActions({
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

class AppMenuAssetActions {
  const AppMenuAssetActions({
    required this.revealAssetInFinder,
    required this.toggleWindowSelected,
    required this.fitWindowToContent,
    required this.restorePreviousWindowZOrder,
    required this.convertVideoWindowToJpeg,
    required this.closeWindow,
  });

  final Future<void> Function(Asset asset) revealAssetInFinder;
  final ValueChanged<String> toggleWindowSelected;
  final ValueChanged<String> fitWindowToContent;
  final ValueChanged<String> restorePreviousWindowZOrder;
  final Future<void> Function(String windowId) convertVideoWindowToJpeg;
  final void Function(String workspaceId, String windowId) closeWindow;
}

class AppMenuWorkspaceActions {
  const AppMenuWorkspaceActions({
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

class AppMenuWindowActions {
  const AppMenuWindowActions({required this.restoreRecentlyClosedWindow});

  final void Function([WorkspaceWindowHistoryEntry? entry]) restoreRecentlyClosedWindow;
}

class AppMenuBindings {
  const AppMenuBindings({
    required this.state,
    required this.app,
    required this.file,
    required this.asset,
    required this.workspace,
    required this.window,
  });

  final AppMenuState state;
  final AppMenuAppActions app;
  final AppMenuFileActions file;
  final AppMenuAssetActions asset;
  final AppMenuWorkspaceActions workspace;
  final AppMenuWindowActions window;
}

class AppMenuBindingBuilder {
  const AppMenuBindingBuilder({
    required this.state,
    required this.foundation,
    required this.documents,
    required this.workspace,
    required this.feedback,
    required this.settings,
    required this.openAssets,
    required this.confirmCollateWorkspaceWindows,
  });

  final AppRuntimeState state;
  final AppFoundation foundation;
  final AppDocument documents;
  final AppWorkspaceServices workspace;
  final AppFeedbackController feedback;
  final AppSettingsController settings;
  final Future<void> Function() openAssets;
  final Future<void> Function() confirmCollateWorkspaceWindows;

  AppMenuState _buildState() {
    final focusedWindow = workspace.workspaceWindowController.focusedWindowOrNull();
    final focusedWindowIsSelected =
        focusedWindow != null && workspace.workspaceController.expose.contains(focusedWindow.asset.id);

    return AppMenuState(
      activeWorkspaceId: state.environmentStoreState.environment?.activeWorkspaceId,
      focusedWindow: focusedWindow,
      focusedWindowIsSelected: focusedWindowIsSelected,
      recentlyClosedWindows: state.workspaceWindowHistoryState.entries,
    );
  }

  AppMenuAppActions _buildAppActions() {
    return AppMenuAppActions(showAboutSerenity: feedback.showAboutSerenity, openSettings: settings.openSettings);
  }

  AppMenuFileActions _buildFileActions() {
    return AppMenuFileActions(
      createEnvironment: documents.documentCoordinator.createDocument,
      openEnvironment: documents.documentCoordinator.openDocument,
      openAssets: openAssets,
      saveEnvironment: documents.documentCoordinator.saveDocument,
      saveEnvironmentAs: documents.documentCoordinator.saveDocumentAs,
    );
  }

  AppMenuAssetActions _buildAssetActions() {
    return AppMenuAssetActions(
      revealAssetInFinder: foundation.platformBridge.revealAssetInFinder,
      toggleWindowSelected: workspace.environmentController.navigation.toggleSelectedWindow,
      fitWindowToContent: workspace.workspaceWindowController.fitWindowToContent,
      restorePreviousWindowZOrder: workspace.workspaceWindowController.restorePreviousWindowZOrder,
      convertVideoWindowToJpeg: workspace.workspaceVideoConversionController.convertVideoWindowToJpeg,
      closeWindow: workspace.workspaceWindowHistoryController.removeWindow,
    );
  }

  AppMenuWorkspaceActions _buildWorkspaceActions() {
    return AppMenuWorkspaceActions(
      toggleExpose: foundation.appUiController.toggleExpose,
      toggleWorkspaceOverview: workspace.environmentController.navigation.toggleOverview,
      createWorkspace: workspace.environmentController.management.create,
      switchToPreviousWorkspace: () => workspace.environmentController.navigation.switchWorkspace(-1),
      switchToNextWorkspace: () => workspace.environmentController.navigation.switchWorkspace(1),
      fitWorkspaceViewportToContent: workspace.workspaceWindowController.fitWorkspaceViewportToContent,
      confirmCollateWorkspaceWindows: confirmCollateWorkspaceWindows,
      pauseAllVideos: workspace.workspaceWindowController.pauseAllVideos,
      showNoWorkspaceToRenameMessage: () => feedback.showMessage('There is no workspace to rename.'),
      renameWorkspace: workspace.environmentController.management.renameWorkspace,
      showNoWorkspaceToDeleteMessage: () => feedback.showMessage('There is no workspace to delete.'),
      confirmDeleteWorkspace: workspace.environmentController.management.confirmDeleteWorkspace,
    );
  }

  AppMenuWindowActions _buildWindowActions() {
    return AppMenuWindowActions(
      restoreRecentlyClosedWindow: workspace.workspaceWindowHistoryController.restoreRecentlyClosedWindow,
    );
  }

  AppMenuBindings build() {
    return AppMenuBindings(
      state: _buildState(),
      app: _buildAppActions(),
      file: _buildFileActions(),
      asset: _buildAssetActions(),
      workspace: _buildWorkspaceActions(),
      window: _buildWindowActions(),
    );
  }
}

class AppMenu extends StatelessWidget {
  const AppMenu({
    super.key,
    required this.state,
    required this.app,
    required this.file,
    required this.asset,
    required this.workspace,
    required this.window,
    required this.child,
  });

  final AppMenuState state;
  final AppMenuAppActions app;
  final AppMenuFileActions file;
  final AppMenuAssetActions asset;
  final AppMenuWorkspaceActions workspace;
  final AppMenuWindowActions window;
  final Widget child;

  List<PlatformMenuItem> _buildWindowMenuItems() {
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

  List<PlatformMenuItem> _buildAppMenuItems() {
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

  List<PlatformMenuItem> _buildFileMenuItems() {
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

  List<PlatformMenuItem> _buildAssetMenuItems() {
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
            onSelected: focusedWindow == null ? null : () => asset.toggleWindowSelected(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
          ),
          PlatformMenuItem(
            label: 'Fit to Content',
            onSelected: focusedWindow == null ? null : () => asset.fitWindowToContent(focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
          ),
          PlatformMenuItem(
            label: 'Send Back',
            onSelected: focusedWindow == null ? null : () => asset.restorePreviousWindowZOrder(focusedWindow.asset.id),
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
                : () => asset.closeWindow(state.activeWorkspaceId!, focusedWindow.asset.id),
            shortcut: const SingleActivator(LogicalKeyboardKey.backspace, meta: true),
          ),
        ],
      ),
    ];
  }

  List<PlatformMenuItem> _buildViewMenuItems() {
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

  List<PlatformMenuItem> _buildWorkspaceMenuItems() {
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

  List<PlatformMenuItem> _buildMenus() {
    return [
      PlatformMenu(label: 'Serenity', menus: _buildAppMenuItems()),
      PlatformMenu(label: 'File', menus: _buildFileMenuItems()),
      PlatformMenu(label: 'Asset', menus: _buildAssetMenuItems()),
      PlatformMenu(label: 'View', menus: _buildViewMenuItems()),
      PlatformMenu(label: 'Workspace', menus: _buildWorkspaceMenuItems()),
      PlatformMenu(label: 'Window', menus: _buildWindowMenuItems()),
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
    return PlatformMenuBar(menus: _buildMenus(), child: child);
  }
}

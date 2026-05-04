import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/app/menu/app_menu_bindings.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

export 'package:serenity_viewer/src/app/menu/app_menu_bindings.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key, required this.child});

  final Widget child;

  List<PlatformMenuItem> _buildWindowMenuItems({
    required AppMenuState state,
    required AppMenuWindowActions window,
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

  List<PlatformMenuItem> _buildAppMenuItems({required AppMenuAppActions app}) {
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

  List<PlatformMenuItem> _buildFileMenuItems({required AppMenuFileActions file}) {
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

  List<PlatformMenuItem> _buildAssetMenuItems({
    required AppMenuState state,
    required AppMenuAssetActions asset,
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

  List<PlatformMenuItem> _buildViewMenuItems({required AppMenuWorkspaceActions workspace}) {
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
    required AppMenuState state,
    required AppMenuWorkspaceActions workspace,
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
    required AppMenuState state,
    required AppMenuAppActions app,
    required AppMenuFileActions file,
    required AppMenuAssetActions asset,
    required AppMenuWorkspaceActions workspace,
    required AppMenuWindowActions window,
  }) {
    return [
      PlatformMenu(label: 'Serenity', menus: _buildAppMenuItems(app: app)),
      PlatformMenu(label: 'File', menus: _buildFileMenuItems(file: file)),
      PlatformMenu(label: 'Asset', menus: _buildAssetMenuItems(state: state, asset: asset)),
      PlatformMenu(label: 'View', menus: _buildViewMenuItems(workspace: workspace)),
      PlatformMenu(label: 'Workspace', menus: _buildWorkspaceMenuItems(state: state, workspace: workspace)),
      PlatformMenu(label: 'Window', menus: _buildWindowMenuItems(state: state, window: window)),
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
    final bindings = buildAppMenuBindings(context);
    return PlatformMenuBar(
      menus: _buildMenus(
        state: bindings.state,
        app: bindings.app,
        file: bindings.file,
        asset: bindings.asset,
        workspace: bindings.workspace,
        window: bindings.window,
      ),
      child: child,
    );
  }
}

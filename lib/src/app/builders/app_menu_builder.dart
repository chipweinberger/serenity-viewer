import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/history/workspace_window_history_entry.dart';

class AppMenuBuilder {
  AppMenuBuilder({
    required this.showAboutSerenity,
    required this.openSettings,
    required this.createEnvironment,
    required this.openEnvironment,
    required this.openAssets,
    required this.saveEnvironment,
    required this.saveEnvironmentAs,
    required this.revealAssetInFinder,
    required this.toggleWindowSelected,
    required this.fitWindowToContent,
    required this.restorePreviousWindowZOrder,
    required this.convertVideoWindowToJpeg,
    required this.closeWindow,
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
    required this.restoreRecentlyClosedWindow,
  });

  final VoidCallback showAboutSerenity;
  final Future<void> Function() openSettings;
  final Future<void> Function() createEnvironment;
  final Future<void> Function() openEnvironment;
  final Future<void> Function() openAssets;
  final Future<void> Function() saveEnvironment;
  final Future<void> Function() saveEnvironmentAs;
  final Future<void> Function(Asset asset) revealAssetInFinder;
  final ValueChanged<String> toggleWindowSelected;
  final ValueChanged<String> fitWindowToContent;
  final ValueChanged<String> restorePreviousWindowZOrder;
  final Future<void> Function(String windowId) convertVideoWindowToJpeg;
  final void Function(String workspaceId, String windowId) closeWindow;
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
  final void Function([WorkspaceWindowHistoryEntry? entry]) restoreRecentlyClosedWindow;

  List<PlatformMenuItem> build({
    required String? activeWorkspaceId,
    required Window? focusedWindow,
    required bool focusedWindowIsSelected,
    required List<WorkspaceWindowHistoryEntry> recentlyClosedWindows,
  }) {
    final focusedVideoWindow = focusedWindow?.asset.type == AssetType.video ? focusedWindow : null;
    final focusedWindowLabel = focusedWindow == null
        ? 'No Asset Selected'
        : _middleTruncatedLabel(focusedWindow.asset.filename);
    final recentlyClosedItems = recentlyClosedWindows.take(8).map((entry) {
      return PlatformMenuItem(
        label: 'Restore ${entry.window.asset.filename}',
        onSelected: () => restoreRecentlyClosedWindow(entry),
      );
    }).toList();

    return [
      PlatformMenu(
        label: 'Serenity',
        menus: [
          PlatformMenuItem(label: 'About Serenity', onSelected: showAboutSerenity),
          PlatformMenuItem(
            label: 'Settings',
            onSelected: () => unawaited(openSettings()),
            shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true),
          ),
          PlatformMenuItem(
            label: 'Quit Serenity',
            onSelected: _quitApplication,
            shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
          ),
        ],
      ),
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItem(
            label: 'New Environment…',
            onSelected: () => unawaited(createEnvironment()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Open Environment…',
            onSelected: () => unawaited(openEnvironment()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Open Assets…',
            onSelected: () => unawaited(openAssets()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
          ),
          PlatformMenuItem(
            label: 'Save',
            onSelected: () => unawaited(saveEnvironment()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
          ),
          PlatformMenuItem(
            label: 'Save As…',
            onSelected: () => unawaited(saveEnvironmentAs()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Asset',
        menus: [
          PlatformMenuItem(label: focusedWindowLabel, onSelected: null),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Reveal in Finder',
                onSelected: focusedWindow == null ? null : () => unawaited(revealAssetInFinder(focusedWindow.asset)),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true),
              ),
              PlatformMenuItem(
                label: focusedWindowIsSelected ? 'Deselect' : 'Select',
                onSelected: focusedWindow == null ? null : () => toggleWindowSelected(focusedWindow.asset.id),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
              ),
              PlatformMenuItem(
                label: 'Fit to Content',
                onSelected: focusedWindow == null ? null : () => fitWindowToContent(focusedWindow.asset.id),
                shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
              ),
              PlatformMenuItem(
                label: 'Send Back',
                onSelected: focusedWindow == null ? null : () => restorePreviousWindowZOrder(focusedWindow.asset.id),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true),
              ),
              PlatformMenuItem(
                label: 'Convert to JPEG',
                onSelected: focusedVideoWindow == null
                    ? null
                    : () => unawaited(convertVideoWindowToJpeg(focusedVideoWindow.asset.id)),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyJ, meta: true, shift: true),
              ),
              PlatformMenuItem(
                label: 'Close',
                onSelected: focusedWindow == null || activeWorkspaceId == null
                    ? null
                    : () => closeWindow(activeWorkspaceId, focusedWindow.asset.id),
                shortcut: const SingleActivator(LogicalKeyboardKey.backspace, meta: true),
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItem(
            label: 'Expose',
            onSelected: toggleExpose,
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp),
          ),
          PlatformMenuItem(
            label: 'View All',
            onSelected: toggleWorkspaceOverview,
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowDown),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Workspace',
        menus: [
          PlatformMenuItem(
            label: 'New',
            onSelected: createWorkspace,
            shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true),
          ),
          PlatformMenuItem(
            label: 'Previous',
            onSelected: switchToPreviousWorkspace,
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowLeft),
          ),
          PlatformMenuItem(
            label: 'Next',
            onSelected: switchToNextWorkspace,
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowRight),
          ),
          PlatformMenuItem(
            label: 'Fit to Assets',
            onSelected: fitWorkspaceViewportToContent,
            shortcut: const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
          ),
          PlatformMenuItem(
            label: 'Collate',
            onSelected: activeWorkspaceId == null ? null : () => unawaited(confirmCollateWorkspaceWindows()),
            shortcut: const SingleActivator(LogicalKeyboardKey.digit3, meta: true),
          ),
          PlatformMenuItem(
            label: 'Pause All',
            onSelected: pauseAllVideos,
            shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Rename…',
            onSelected: activeWorkspaceId == null
                ? showNoWorkspaceToRenameMessage
                : () => unawaited(renameWorkspace(activeWorkspaceId)),
          ),
          PlatformMenuItem(
            label: 'Delete…',
            onSelected: activeWorkspaceId == null
                ? showNoWorkspaceToDeleteMessage
                : () => unawaited(confirmDeleteWorkspace(activeWorkspaceId)),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Window',
        menus: [
          PlatformMenuItem(
            label: 'Restore Last Closed',
            onSelected: recentlyClosedWindows.isEmpty ? null : restoreRecentlyClosedWindow,
            shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true),
          ),
          ...recentlyClosedItems,
        ],
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
}

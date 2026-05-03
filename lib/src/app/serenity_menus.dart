// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellMenus on _SerenityShellState {
  String _middleTruncatedLabel(String value, {int maxLength = 42}) {
    if (value.length <= maxLength) {
      return value;
    }

    final available = maxLength - 1;
    final leadingLength = (available / 2).ceil();
    final trailingLength = (available / 2).floor();
    return '${value.substring(0, leadingLength)}…${value.substring(value.length - trailingLength)}';
  }

  void _quitApplication() {
    unawaited(ServicesBinding.instance.exitApplication(ui.AppExitType.cancelable));
  }

  List<PlatformMenuItem> _buildMenus() {
    final activeWorkspace = _activeWorkspaceOrNull;
    final focusedWindow = _focusedWindowOrNull();
    final focusedVideoWindow = focusedWindow?.asset.type == AssetType.video ? focusedWindow : null;
    final focusedWindowIsSelected =
        focusedWindow != null && _windowInteractionState.selectedExposeWindowIds.contains(focusedWindow.asset.id);
    final focusedWindowLabel = focusedWindow == null
        ? 'No Asset Selected'
        : _middleTruncatedLabel(focusedWindow.asset.filename);
    final recentlyClosedItems = _recentlyClosedWindows.take(8).map((entry) {
      return PlatformMenuItem(
        label: 'Restore ${entry.window.asset.filename}',
        onSelected: () => _restoreRecentlyClosedWindow(entry),
      );
    }).toList();

    return [
      PlatformMenu(
        label: 'Serenity',
        menus: [
          PlatformMenuItem(label: 'About Serenity', onSelected: _showAboutSerenity),
          PlatformMenuItem(
            label: 'Settings',
            onSelected: () => unawaited(_openSettings()),
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
            onSelected: () => unawaited(_createEnvironment()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Open Environment…',
            onSelected: () => unawaited(_openEnvironment()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Open Assets…',
            onSelected: () => unawaited(_pickAndImportAssets()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
          ),
          PlatformMenuItem(
            label: 'Save',
            onSelected: () => unawaited(_saveEnvironment()),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
          ),
          PlatformMenuItem(
            label: 'Save As…',
            onSelected: () => unawaited(_saveEnvironmentAs()),
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
                onSelected: focusedWindow == null ? null : () => unawaited(_showFocusedAssetInFinder()),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true),
              ),
              PlatformMenuItem(
                label: focusedWindowIsSelected ? 'Deselect' : 'Select',
                onSelected: focusedWindow == null ? null : () => _toggleExposeWindowSelected(focusedWindow.asset.id),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
              ),
              PlatformMenuItem(
                label: 'Fit to Content',
                onSelected: focusedWindow == null ? null : () => _fitWindowToContent(focusedWindow.asset.id),
                shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
              ),
              PlatformMenuItem(
                label: 'Send Back',
                onSelected: focusedWindow == null ? null : () => _restorePreviousWindowZOrder(focusedWindow.asset.id),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyB, meta: true, shift: true),
              ),
              PlatformMenuItem(
                label: 'Convert to JPEG',
                onSelected: focusedVideoWindow == null
                    ? null
                    : () => unawaited(_convertVideoWindowToJpeg(focusedVideoWindow.asset.id)),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyJ, meta: true, shift: true),
              ),
              PlatformMenuItem(
                label: 'Close',
                onSelected: focusedWindow == null
                    ? null
                    : () => _removeWindow(_persistenceState.session!.activeWorkspaceId, focusedWindow.asset.id),
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
            onSelected: _toggleExpose,
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp),
          ),
          PlatformMenuItem(
            label: 'View All',
            onSelected: () => unawaited(_toggleWorkspaceOverview()),
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowDown),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Workspace',
        menus: [
          PlatformMenuItem(
            label: 'New',
            onSelected: _createWorkspace,
            shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true),
          ),
          PlatformMenuItem(
            label: 'Previous',
            onSelected: () => unawaited(_switchWorkspace(-1)),
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowLeft),
          ),
          PlatformMenuItem(
            label: 'Next',
            onSelected: () => unawaited(_switchWorkspace(1)),
            shortcut: const SingleActivator(LogicalKeyboardKey.arrowRight),
          ),
          PlatformMenuItem(
            label: 'Fit to Assets',
            onSelected: _fitWorkspaceViewportToContent,
            shortcut: const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
          ),
          PlatformMenuItem(
            label: 'Collate',
            onSelected: activeWorkspace == null ? null : () => unawaited(_confirmCollateWorkspaceWindows()),
            shortcut: const SingleActivator(LogicalKeyboardKey.digit3, meta: true),
          ),
          PlatformMenuItem(
            label: 'Pause All',
            onSelected: _pauseAllVideos,
            shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
          ),
          PlatformMenuItem(
            label: 'Rename…',
            onSelected: activeWorkspace == null
                ? () => _showMessage('There is no workspace to rename.')
                : () => unawaited(_renameWorkspace(activeWorkspace.id)),
          ),
          PlatformMenuItem(
            label: 'Delete…',
            onSelected: activeWorkspace == null
                ? () => _showMessage('There is no workspace to delete.')
                : () => unawaited(_confirmDeleteWorkspace(activeWorkspace.id)),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Window',
        menus: [
          PlatformMenuItem(
            label: 'Restore Last Closed',
            onSelected: _recentlyClosedWindows.isEmpty ? null : _restoreRecentlyClosedWindow,
            shortcut: const SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true),
          ),
          ...recentlyClosedItems,
        ],
      ),
    ];
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_state.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_controller.dart';
import 'package:serenity_viewer/src/workspace/shell/workspace_shell_navigation.dart';

class WorkspaceShellShortcutsDependencies {
  const WorkspaceShellShortcutsDependencies({
    required this.chromeState,
    required this.workspaceLinksController,
    required this.focusedWindowOrNull,
    required this.showWorkspaceScreen,
    required this.toggleExpose,
    required this.toggleVideoPlayback,
    required this.navigation,
  });

  final ChromeState chromeState;
  final LinksController workspaceLinksController;
  final Window? Function() focusedWindowOrNull;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final VoidCallback toggleExpose;
  final ValueChanged<String> toggleVideoPlayback;
  final WorkspaceShellNavigationApi navigation;
}

class WorkspaceShellShortcutsApi {
  WorkspaceShellShortcutsApi(this._dependencies);

  final WorkspaceShellShortcutsDependencies _dependencies;

  void handleShortcut(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_dependencies.chromeState.screen == SerenityScreen.library) {
        _dependencies.showWorkspaceScreen(clearExposeSelection: false);
      } else if (_dependencies.chromeState.screen == SerenityScreen.workspace &&
          _dependencies.chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
        _dependencies.toggleExpose();
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_dependencies.chromeState.screen == SerenityScreen.workspace &&
          _dependencies.chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose) {
        _dependencies.showWorkspaceScreen(clearExposeSelection: false);
      } else if (_dependencies.chromeState.screen == SerenityScreen.workspace) {
        _dependencies.navigation.toggleOverview();
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      _dependencies.navigation.switchWorkspace(-1);
      return;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      _dependencies.navigation.switchWorkspace(1);
      return;
    }

    if (key == LogicalKeyboardKey.space) {
      final focusedWindow = _dependencies.focusedWindowOrNull();
      if (focusedWindow?.asset.type == AssetType.video) {
        _dependencies.toggleVideoPlayback(focusedWindow!.asset.id);
      }
    }
  }

  KeyEventResult onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_dependencies.workspaceLinksController.shouldHandlePasteLinksShortcut(event)) {
      unawaited(_dependencies.workspaceLinksController.pasteLinksFromClipboard());
      return KeyEventResult.handled;
    }

    final key = event.logicalKey;
    if ({
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.space,
    }.contains(key)) {
      handleShortcut(key);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

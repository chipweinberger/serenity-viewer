import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/app/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';

class WorkspaceShortcutDependencies {
  const WorkspaceShortcutDependencies({
    required this.appUiState,
    required this.workspaceLinksController,
    required this.focusedWindowOrNull,
    required this.showWorkspaceScreen,
    required this.toggleExpose,
    required this.toggleVideoPlayback,
    required this.navigation,
  });

  final AppUiState appUiState;
  final WorkspaceLinksController workspaceLinksController;
  final Window? Function() focusedWindowOrNull;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final VoidCallback toggleExpose;
  final ValueChanged<String> toggleVideoPlayback;
  final EnvironmentNavigationController navigation;
}

class WorkspaceShortcutController {
  WorkspaceShortcutController(this._dependencies);

  final WorkspaceShortcutDependencies _dependencies;

  void handleShortcut(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_dependencies.appUiState.screen == SerenityScreen.library) {
        _dependencies.showWorkspaceScreen(clearExposeSelection: false);
      } else if (_dependencies.appUiState.screen == SerenityScreen.workspace &&
          _dependencies.appUiState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
        _dependencies.toggleExpose();
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_dependencies.appUiState.screen == SerenityScreen.workspace &&
          _dependencies.appUiState.workspaceLayoutMode == WorkspaceLayoutMode.expose) {
        _dependencies.showWorkspaceScreen(clearExposeSelection: false);
      } else if (_dependencies.appUiState.screen == SerenityScreen.workspace) {
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

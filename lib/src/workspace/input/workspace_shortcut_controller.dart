import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_controller_types.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_playback_controller.dart';
import 'package:serenity_viewer/src/workspace/links/workspace_links_controller.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';

class WorkspaceShortcutDependencies {
  const WorkspaceShortcutDependencies({
    required this.appUiState,
    required this.appUiController,
    required this.playbackController,
    required this.workspaceLinksController,
    required this.focusedWindowOrNull,
    required this.activeWorkspaceId,
    required this.showWorkspaceScreen,
    required this.management,
    required this.navigation,
  });

  final AppUiState appUiState;
  final AppUiController appUiController;
  final WorkspacePlaybackController playbackController;
  final WorkspaceLinksController workspaceLinksController;
  final Window? Function() focusedWindowOrNull;
  final String? Function() activeWorkspaceId;
  final SerenityShowWorkspaceScreen showWorkspaceScreen;
  final EnvironmentManagementController management;
  final EnvironmentNavigationController navigation;
}

class WorkspaceShortcutController {
  WorkspaceShortcutController(this._dependencies);

  final WorkspaceShortcutDependencies _dependencies;

  void _renameActiveWorkspace() {
    final activeWorkspaceId = _dependencies.activeWorkspaceId();
    if (activeWorkspaceId == null) {
      return;
    }
    unawaited(_dependencies.management.renameWorkspace(activeWorkspaceId));
  }

  void _deleteActiveWorkspace() {
    final activeWorkspaceId = _dependencies.activeWorkspaceId();
    if (activeWorkspaceId == null) {
      return;
    }
    unawaited(_dependencies.management.confirmDeleteWorkspace(activeWorkspaceId));
  }

  void handleShortcut(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_dependencies.appUiState.screen == SerenityScreen.library) {
        _dependencies.showWorkspaceScreen(clearExposeSelection: false);
      } else if (_dependencies.appUiState.screen == SerenityScreen.workspace &&
          _dependencies.appUiState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
        _dependencies.appUiController.toggleExpose();
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
        if (!_dependencies.appUiState.shouldLoadVideos) {
          _dependencies.appUiController.loadVideos();
        }
        _dependencies.playbackController.toggleVideoPlayback(focusedWindow!.asset.id);
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
    if (HardwareKeyboard.instance.isMetaPressed && HardwareKeyboard.instance.isShiftPressed) {
      if (key == LogicalKeyboardKey.keyW) {
        _renameActiveWorkspace();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyD) {
        _deleteActiveWorkspace();
        return KeyEventResult.handled;
      }
    }

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

part of 'workspace_shell_controller.dart';

class WorkspaceShellShortcutsApi {
  WorkspaceShellShortcutsApi._(this._controller);

  final WorkspaceShellController _controller;

  void handleShortcut(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_controller.chromeState.screen == SerenityScreen.library) {
        _controller.showWorkspaceScreen(clearExposeSelection: false);
      } else if (_controller.chromeState.screen == SerenityScreen.workspace &&
          _controller.chromeState.workspaceLayoutMode != WorkspaceLayoutMode.expose) {
        _controller.toggleExpose();
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_controller.chromeState.screen == SerenityScreen.workspace &&
          _controller.chromeState.workspaceLayoutMode == WorkspaceLayoutMode.expose) {
        _controller.showWorkspaceScreen(clearExposeSelection: false);
      } else if (_controller.chromeState.screen == SerenityScreen.workspace) {
        _controller.navigation.toggleOverview();
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      _controller.navigation.switchWorkspace(-1);
      return;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      _controller.navigation.switchWorkspace(1);
      return;
    }

    if (key == LogicalKeyboardKey.space) {
      final focusedWindow = _controller.focusedWindowOrNull();
      if (focusedWindow?.asset.type == AssetType.video) {
        _controller.toggleVideoPlayback(focusedWindow!.asset.id);
      }
    }
  }

  KeyEventResult onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_controller.workspaceLinksController.shouldHandlePasteLinksShortcut(event)) {
      unawaited(_controller.workspaceLinksController.pasteLinksFromClipboard());
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

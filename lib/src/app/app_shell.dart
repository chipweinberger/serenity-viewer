import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/controllers/app_ui_controller.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/app/state/window_workspace_drag_state.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';
import 'package:serenity_viewer/src/window/interaction/window_interaction_state.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  ({bool hasEnvironment, bool isLoading, SerenityScreen screen, String? draggingWindowSourceWorkspaceId}) _watchState(
    BuildContext context,
  ) {
    return (
      screen: context.select((AppUiState state) => state.screen),
      draggingWindowSourceWorkspaceId: context.select((WindowWorkspaceDragState state) => state.sourceWorkspaceId),
      isLoading: context.select((EnvironmentStoreState state) => state.isLoading),
      hasEnvironment: context.select((EnvironmentStoreState state) => state.environment != null),
    );
  }

  int _activeScreenIndex(SerenityScreen screen) {
    return switch (screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildMainView(SerenityScreen screen) {
    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex(screen),
            children: [const WorkspaceView(), const LibraryView()],
          ),
        ),
        const AppHeader(),
      ],
    );
  }

  Widget _buildContent({required bool isLoading, required bool hasEnvironment, required SerenityScreen screen}) {
    if (isLoading || !hasEnvironment) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildMainView(screen);
  }

  KeyEventResult _handleKeyEvent(
    KeyEvent event,
    WorkspaceController workspaceController,
    WindowInteractionState windowInteractionState,
  ) {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    windowInteractionState.setModifierKeys(
      isCommandPressed: isCommandPressed(pressedKeys),
      isOptionPressed: isOptionPressed(pressedKeys),
    );
    return workspaceController.shortcuts.onKeyEvent(event);
  }

  void _handlePointerMove(
    PointerMoveEvent event,
    WindowWorkspaceDragState windowWorkspaceDragState,
    AppUiController appUiController,
    AppUiHandles uiHandles,
  ) {
    final sourceWorkspaceId = windowWorkspaceDragState.sourceWorkspaceId;
    if (sourceWorkspaceId == null || event.buttons != kPrimaryMouseButton) {
      return;
    }

    final targetWorkspaceId = uiHandles.workspaceTabAt(event.position, excludingWorkspaceId: sourceWorkspaceId);
    appUiController.setWindowDragTargetWorkspaceId(targetWorkspaceId);
  }

  void _handlePointerEnd(WindowWorkspaceDragState windowWorkspaceDragState, AppUiController appUiController) {
    if (windowWorkspaceDragState.sourceWorkspaceId == null) {
      return;
    }

    appUiController.endWindowDrag();
  }

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final uiHandles = context.read<AppUiHandles>();
    final windowWorkspaceDragState = context.read<WindowWorkspaceDragState>();
    final appUiController = context.read<AppUiController>();
    final workspaceController = context.read<WorkspaceController>();
    final windowInteractionState = context.read<WindowInteractionState>();

    return AppMenu(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (event) => _handlePointerMove(event, windowWorkspaceDragState, appUiController, uiHandles),
        onPointerUp: (_) => _handlePointerEnd(windowWorkspaceDragState, appUiController),
        onPointerCancel: (_) => _handlePointerEnd(windowWorkspaceDragState, appUiController),
        child: Focus(
          focusNode: uiHandles.focusNode,
          autofocus: true,
          onKeyEvent: (_, event) => _handleKeyEvent(event, workspaceController, windowInteractionState),
          child: Scaffold(
            body: SafeArea(
              top: false,
              child: _buildContent(
                isLoading: state.isLoading,
                hasEnvironment: state.hasEnvironment,
                screen: state.screen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

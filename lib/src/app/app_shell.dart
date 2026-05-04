import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  AppUiState _watchUiState(BuildContext context) {
    return context.watch<AppUiState>();
  }

  int _activeScreenIndex(AppUiState appUiState) {
    return switch (appUiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  Widget _buildMainView(AppUiState appUiState) {
    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(
            index: _activeScreenIndex(appUiState),
            children: [const WorkspaceView(), const LibraryView()],
          ),
        ),
        const AppHeader(),
      ],
    );
  }

  Widget _buildContent(EnvironmentStoreState environmentStoreState, AppUiState appUiState) {
    if (environmentStoreState.isLoading || environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildMainView(appUiState);
  }

  @override
  Widget build(BuildContext context) {
    final appUiState = _watchUiState(context);
    final uiHandles = context.read<AppUiHandles>();
    final workspaceShortcutController = context.read<WorkspaceShortcutController>();
    final environmentStoreState = context.watch<EnvironmentStoreState>();

    return AppMenu(
      child: Focus(
        focusNode: uiHandles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => workspaceShortcutController.onKeyEvent(event),
        child: Scaffold(body: SafeArea(top: false, child: _buildContent(environmentStoreState, appUiState))),
      ),
    );
  }
}

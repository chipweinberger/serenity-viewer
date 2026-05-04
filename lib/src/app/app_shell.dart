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
import 'package:serenity_viewer/src/workspace/controllers/workspace_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  ({bool hasEnvironment, bool isLoading, SerenityScreen screen}) _watchState(BuildContext context) {
    return (
      screen: context.select((AppUiState state) => state.screen),
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

  @override
  Widget build(BuildContext context) {
    final state = _watchState(context);
    final uiHandles = context.read<AppUiHandles>();
    final workspaceController = context.read<WorkspaceController>();

    return AppMenu(
      child: Focus(
        focusNode: uiHandles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => workspaceController.shortcuts.onKeyEvent(event),
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
    );
  }
}

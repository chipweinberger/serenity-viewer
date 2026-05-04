import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/menu/app_menu.dart';
import 'package:serenity_viewer/src/app/state/app_ui_handles.dart';
import 'package:serenity_viewer/src/app/views/app_main_view.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/workspace/input/workspace_shortcut_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  Widget _buildContent(EnvironmentStoreState environmentStoreState) {
    if (environmentStoreState.isLoading || environmentStoreState.environment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return const AppMainView();
  }

  @override
  Widget build(BuildContext context) {
    final uiHandles = context.read<AppUiHandles>();
    final workspaceShortcutController = context.read<WorkspaceShortcutController>();
    final environmentStoreState = context.watch<EnvironmentStoreState>();

    return AppMenu(
      child: Focus(
        focusNode: uiHandles.focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => workspaceShortcutController.onKeyEvent(event),
        child: Scaffold(body: SafeArea(top: false, child: _buildContent(environmentStoreState))),
      ),
    );
  }
}

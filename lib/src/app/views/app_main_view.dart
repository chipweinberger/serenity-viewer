import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:serenity_viewer/src/app/header/app_header.dart';
import 'package:serenity_viewer/src/app/state/app_ui_state.dart';
import 'package:serenity_viewer/src/app/views/library_view.dart';
import 'package:serenity_viewer/src/app/views/workspace_view.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class AppMainView extends StatelessWidget {
  const AppMainView({super.key});

  AppUiState _watchState(BuildContext context) {
    return context.watch<AppUiState>();
  }

  int _activeScreenIndex(AppUiState appUiState) {
    return switch (appUiState.screen) {
      SerenityScreen.workspace => 0,
      SerenityScreen.library => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appUiState = _watchState(context);

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
}

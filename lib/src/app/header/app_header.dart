import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/header/app_tab_bar_actions.dart';
import 'package:serenity_viewer/src/app/header/app_window_title.dart';
import 'package:serenity_viewer/src/app/header/app_tab_bar.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.windowTitle,
    required this.openWorkspaces,
    required this.activeWorkspaceId,
    required this.isLibraryScreen,
    required this.shouldMoveSelectedWindows,
    required this.draggingTabWorkspaceId,
    required this.tabScrollController,
    required this.actions,
  });

  final String windowTitle;
  final List<Workspace> openWorkspaces;
  final String activeWorkspaceId;
  final bool isLibraryScreen;
  final bool shouldMoveSelectedWindows;
  final String? draggingTabWorkspaceId;
  final ScrollController tabScrollController;
  final AppTabBarActions actions;

  Widget _buildPointerShield() {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 84,
      child: AbsorbPointer(absorbing: true, child: ColoredBox(color: Colors.transparent)),
    );
  }

  Widget _buildTabBar() {
    return Positioned(
      left: 18,
      right: 18,
      top: 28,
      child: AppTabBar(
        openWorkspaces: openWorkspaces,
        activeWorkspaceId: activeWorkspaceId,
        isLibraryScreen: isLibraryScreen,
        shouldMoveSelectedWindows: shouldMoveSelectedWindows,
        draggingTabWorkspaceId: draggingTabWorkspaceId,
        tabScrollController: tabScrollController,
        actions: actions,
      ),
    );
  }

  Widget _buildTitle() {
    return Positioned(
      top: 10,
      left: 120,
      right: 120,
      child: Center(child: AppWindowTitle(windowTitle: windowTitle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildPointerShield(), _buildTabBar(), _buildTitle()]);
  }
}

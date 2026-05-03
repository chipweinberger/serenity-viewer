// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/app_shell/app_shell.dart';

extension _AppShellEnvironmentActions on _AppShellState {
  void _updateEnvironment(Environment nextEnvironment) {
    _environmentController.updateEnvironment(nextEnvironment);
  }

  void _replaceWorkspace(Workspace nextWorkspace, {bool queueThumbnail = true}) {
    _environmentController.replaceWorkspace(nextWorkspace, queueThumbnail: queueThumbnail);
  }

  void _toggleExpose() {
    _chromeController.toggleExpose();
  }
}

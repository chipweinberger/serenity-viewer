import 'package:serenity_viewer/src/environment/session/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_expose_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_view_controller.dart';
import 'package:serenity_viewer/src/environment/session/environment_shortcut_controller.dart';
import 'package:serenity_viewer/src/environment/session/workspace_view_tracking_controller.dart';

class EnvironmentSession {
  const EnvironmentSession({
    required this.navigation,
    required this.expose,
    required this.management,
    required this.shortcuts,
    required this.tracking,
  });

  final EnvironmentViewController navigation;
  final EnvironmentExposeController expose;
  final EnvironmentManagementController management;
  final EnvironmentShortcutController shortcuts;
  final WorkspaceViewTrackingController tracking;
}

import 'package:serenity_viewer/src/environment/history/environment_window_history_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';

class EnvironmentController {
  const EnvironmentController({required this.navigation, required this.management, required this.history});

  final EnvironmentNavigationController navigation;
  final EnvironmentManagementController management;
  final EnvironmentWindowHistoryController history;
}

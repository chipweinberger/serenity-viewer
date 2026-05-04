import 'package:serenity_viewer/src/environment/controller/environment_management_controller.dart';
import 'package:serenity_viewer/src/environment/controller/environment_navigation_controller.dart';

class EnvironmentController {
  const EnvironmentController({required this.navigation, required this.management});

  final EnvironmentNavigationController navigation;
  final EnvironmentManagementController management;
}

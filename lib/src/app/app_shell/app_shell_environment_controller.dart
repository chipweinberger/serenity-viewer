import 'package:serenity_viewer/src/app/environment/app_environment_controller.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/behavior/chrome_controller.dart';

class AppShellEnvironmentController {
  const AppShellEnvironmentController({required this.environmentController, required this.chromeController});

  final EnvironmentController environmentController;
  final ChromeController chromeController;

  void updateEnvironment(Environment nextEnvironment) {
    environmentController.updateEnvironment(nextEnvironment);
  }

  void replaceWorkspace(Workspace nextWorkspace, {bool queueThumbnail = true}) {
    environmentController.replaceWorkspace(nextWorkspace, queueThumbnail: queueThumbnail);
  }

  void toggleExpose() {
    chromeController.toggleExpose();
  }
}

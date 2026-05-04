import 'package:serenity_viewer/src/environment/environment.dart';

class EnvironmentStoreState {
  Environment? environment;
  String? currentEnvironmentPath;
  bool hasUnsavedChanges = false;
  bool isLoading = true;
  bool isPromptingForStartupEnvironment = false;
}

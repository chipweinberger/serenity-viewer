import 'package:serenity_viewer/src/models/serenity_session_state.dart';

class SerenityShellPersistenceState {
  SerenitySessionState? session;
  String? currentEnvironmentPath;
  bool hasUnsavedChanges = false;
  bool isLoading = true;
  bool isPromptingForStartupEnvironment = false;
}

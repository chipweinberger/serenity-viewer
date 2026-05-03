import 'package:serenity_viewer/src/sry_document/models/session_state.dart';

class ShellPersistenceState {
  SessionState? session;
  String? currentEnvironmentPath;
  bool hasUnsavedChanges = false;
  bool isLoading = true;
  bool isPromptingForStartupEnvironment = false;
}

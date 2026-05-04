import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/environment.dart';

class EnvironmentStoreState extends ChangeNotifier {
  static const Object _noChange = Object();

  Environment? _environment;
  String? _currentEnvironmentPath;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  bool _isPromptingForStartupEnvironment = false;

  Environment? get environment => _environment;
  String? get currentEnvironmentPath => _currentEnvironmentPath;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isLoading => _isLoading;
  bool get isPromptingForStartupEnvironment => _isPromptingForStartupEnvironment;

  bool update({
    Object? environment = _noChange,
    Object? currentEnvironmentPath = _noChange,
    bool? hasUnsavedChanges,
    bool? isLoading,
    bool? isPromptingForStartupEnvironment,
  }) {
    final nextEnvironment = environment == _noChange ? _environment : environment as Environment?;
    final nextCurrentEnvironmentPath = currentEnvironmentPath == _noChange
        ? _currentEnvironmentPath
        : currentEnvironmentPath as String?;
    final nextHasUnsavedChanges = hasUnsavedChanges ?? _hasUnsavedChanges;
    final nextIsLoading = isLoading ?? _isLoading;
    final nextIsPromptingForStartupEnvironment = isPromptingForStartupEnvironment ?? _isPromptingForStartupEnvironment;
    final changed =
        nextEnvironment != _environment ||
        nextCurrentEnvironmentPath != _currentEnvironmentPath ||
        nextHasUnsavedChanges != _hasUnsavedChanges ||
        nextIsLoading != _isLoading ||
        nextIsPromptingForStartupEnvironment != _isPromptingForStartupEnvironment;
    if (!changed) {
      return false;
    }

    _environment = nextEnvironment;
    _currentEnvironmentPath = nextCurrentEnvironmentPath;
    _hasUnsavedChanges = nextHasUnsavedChanges;
    _isLoading = nextIsLoading;
    _isPromptingForStartupEnvironment = nextIsPromptingForStartupEnvironment;
    notifyListeners();
    return true;
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:serenity_viewer/src/app/app_shell_runtime/app_shell_runtime.dart';
import 'package:serenity_viewer/src/environment/environment.dart';

class AppShellPersistenceController {
  const AppShellPersistenceController({
    required this.state,
    required this.foundation,
    required this.documents,
    required this.mounted,
    required this.seedEnvironment,
    required this.isRunningInWidgetTest,
  });

  final AppShellRuntimeStateServices state;
  final AppShellRuntimeFoundationServices foundation;
  final AppShellRuntimeDocumentServices documents;
  final bool Function() mounted;
  final Environment Function() seedEnvironment;
  final bool isRunningInWidgetTest;

  Future<void> restoreEnvironment() async {
    if (isRunningInWidgetTest) {
      foundation.environmentController.restoreWidgetTestEnvironment(seedEnvironment());
      return;
    }

    try {
      final lastEnvironmentPath = await foundation.appShellPlatformBridge.loadLastEnvironmentPath();
      if (lastEnvironmentPath != null && lastEnvironmentPath.isNotEmpty && await File(lastEnvironmentPath).exists()) {
        await documents.sryDocumentCoordinator.loadDocumentFromPath(
          lastEnvironmentPath,
          showSuccessMessage: false,
          persistAsLastOpened: true,
        );
        return;
      }
      await foundation.appShellPlatformBridge.storeLastEnvironmentPath(null);
    } catch (_) {
      await foundation.appShellPlatformBridge.storeLastEnvironmentPath(null);
    }

    foundation.environmentController.showMissingStartupState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(documents.sryDocumentCoordinator.promptForStartupDocument());
    });
  }

  Future<void> saveEnvironment({bool force = false}) async {
    final environment = state.persistenceState.environment;
    final environmentPath = state.persistenceState.currentEnvironmentPath;
    if (environment == null || environmentPath == null || environmentPath.isEmpty) {
      return;
    }
    if (!force && !state.persistenceState.hasUnsavedChanges) {
      return;
    }

    try {
      final sessionToSave = await foundation.environmentBookmarkSynchronizer.synchronize(environment);
      foundation.environmentController.applySavedEnvironment(
        originalEnvironment: environment,
        savedEnvironment: sessionToSave,
        mounted: mounted(),
      );
      await documents.sryDocumentCoordinator.saveDocumentToPath(
        environmentPath,
        environmentOverride: sessionToSave,
        showMessageOnFailure: false,
      );
      await foundation.appShellPlatformBridge.syncWindowTitle();
    } catch (_) {
      // Widget tests and unsupported platforms can skip local persistence.
    }
  }
}

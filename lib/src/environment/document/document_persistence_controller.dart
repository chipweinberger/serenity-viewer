import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:serenity_viewer/src/app/runtime/app_runtime.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';

class DocumentPersistenceController {
  const DocumentPersistenceController({
    required this.state,
    required this.foundation,
    required this.documentCoordinator,
    required this.mounted,
    required this.seedEnvironment,
    required this.isRunningInWidgetTest,
  });

  final AppRuntimeState state;
  final AppFoundation foundation;
  final DocumentCoordinator documentCoordinator;
  final bool Function() mounted;
  final Environment Function() seedEnvironment;
  final bool isRunningInWidgetTest;

  Future<void> restoreEnvironment() async {
    if (isRunningInWidgetTest) {
      foundation.environmentStore.restoreWidgetTestEnvironment(seedEnvironment());
      return;
    }

    try {
      final lastEnvironmentPath = await foundation.platformBridge.loadLastEnvironmentPath();
      if (lastEnvironmentPath != null && lastEnvironmentPath.isNotEmpty && await File(lastEnvironmentPath).exists()) {
        await documentCoordinator.loadDocumentFromPath(
          lastEnvironmentPath,
          showSuccessMessage: false,
          persistAsLastOpened: true,
        );
        return;
      }
      await foundation.platformBridge.storeLastEnvironmentPath(null);
    } catch (_) {
      await foundation.platformBridge.storeLastEnvironmentPath(null);
    }

    foundation.environmentStore.showMissingStartupState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(documentCoordinator.promptForStartupDocument());
    });
  }

  Future<void> saveEnvironment({bool force = false}) async {
    final environment = state.environmentStoreState.environment;
    final environmentPath = state.environmentStoreState.currentEnvironmentPath;
    if (environment == null || environmentPath == null || environmentPath.isEmpty) {
      return;
    }
    if (!force && !state.environmentStoreState.hasUnsavedChanges) {
      return;
    }

    try {
      final sessionToSave = await foundation.environmentBookmarkSynchronizer.synchronize(environment);
      foundation.environmentStore.applySavedEnvironment(
        originalEnvironment: environment,
        savedEnvironment: sessionToSave,
        mounted: mounted(),
      );
      await documentCoordinator.saveDocumentToPath(
        environmentPath,
        environmentOverride: sessionToSave,
        showMessageOnFailure: false,
      );
      await foundation.platformBridge.syncWindowTitle();
    } catch (_) {
      // Widget tests and unsupported platforms can skip local persistence.
    }
  }
}

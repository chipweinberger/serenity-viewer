import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/store/environment_bookmark_synchronizer.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/app/platform/platform_bridge.dart';

class DocumentPersistenceController {
  const DocumentPersistenceController({
    required this.environmentStoreState,
    required this.environmentStore,
    required this.platformBridge,
    required this.environmentBookmarkSynchronizer,
    required this.documentCoordinator,
    required this.mounted,
    required this.seedEnvironment,
    required this.isRunningInWidgetTest,
  });

  final EnvironmentStoreState environmentStoreState;
  final EnvironmentStore environmentStore;
  final PlatformBridge platformBridge;
  final EnvironmentBookmarkSynchronizer environmentBookmarkSynchronizer;
  final DocumentCoordinator documentCoordinator;
  final bool Function() mounted;
  final Environment Function() seedEnvironment;
  final bool isRunningInWidgetTest;

  Future<void> restoreEnvironment() async {
    if (isRunningInWidgetTest) {
      environmentStore.restoreWidgetTestEnvironment(seedEnvironment());
      return;
    }

    try {
      final lastEnvironmentPath = await platformBridge.loadLastEnvironmentPath();
      if (lastEnvironmentPath != null && lastEnvironmentPath.isNotEmpty && await File(lastEnvironmentPath).exists()) {
        await documentCoordinator.loadDocumentFromPath(
          lastEnvironmentPath,
          showSuccessMessage: false,
          persistAsLastOpened: true,
        );
        return;
      }
      await platformBridge.storeLastEnvironmentPath(null);
    } catch (_) {
      await platformBridge.storeLastEnvironmentPath(null);
    }

    environmentStore.showMissingStartupState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(documentCoordinator.promptForStartupDocument());
    });
  }

  Future<void> saveEnvironment({bool force = false}) async {
    final environment = environmentStoreState.environment;
    final environmentPath = environmentStoreState.currentEnvironmentPath;
    if (environment == null || environmentPath == null || environmentPath.isEmpty) {
      return;
    }
    if (!force && !environmentStoreState.hasUnsavedChanges) {
      return;
    }

    try {
      final sessionToSave = await environmentBookmarkSynchronizer.synchronize(environment);
      environmentStore.applySavedEnvironment(
        originalEnvironment: environment,
        savedEnvironment: sessionToSave,
        mounted: mounted(),
      );
      await documentCoordinator.saveDocumentToPath(
        environmentPath,
        environmentOverride: sessionToSave,
        showMessageOnFailure: false,
      );
      await platformBridge.syncWindowTitle();
    } catch (_) {
      // Widget tests and unsupported platforms can skip local persistence.
    }
  }
}

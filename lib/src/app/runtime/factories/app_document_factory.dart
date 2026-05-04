import 'package:serenity_viewer/src/app/runtime/app_runtime_inputs.dart';
import 'dart:io';

import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';

DocumentCoordinator createAppDocumentCoordinator({
  required AppRuntimeInputs inputs,
  required EnvironmentStore environmentStore,
  required Future<void> Function() refreshActiveWorkspaceThumbnailIfNeeded,
  required Future<void> Function(String? path) storeLastEnvironmentPath,
  required Future<void> Function() syncWindowTitle,
  required Future<String?> Function(String bookmark) resolveFileBookmark,
  required Future<String?> Function(String path) createFileBookmark,
  required Future<Directory> Function() thumbnailDirectory,
}) {
  return DocumentCoordinator(
    environmentStoreState: inputs.stateStore.environmentStoreState,
    environmentStore: environmentStore,
    context: inputs.context,
    mounted: inputs.mounted,
    seedEnvironment: inputs.seedEnvironment,
    showMessage: inputs.showMessage,
    refreshActiveWorkspaceThumbnailIfNeeded: refreshActiveWorkspaceThumbnailIfNeeded,
    storeLastEnvironmentPath: storeLastEnvironmentPath,
    syncWindowTitle: syncWindowTitle,
    resolveFileBookmark: resolveFileBookmark,
    createFileBookmark: createFileBookmark,
    thumbnailDirectory: thumbnailDirectory,
    updateEnvironment: inputs.updateEnvironment,
    saveEnvironment: inputs.saveEnvironment,
  );
}

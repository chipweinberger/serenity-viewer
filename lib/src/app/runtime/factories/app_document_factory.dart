import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';

DocumentCoordinator createAppDocumentCoordinator({
  required EnvironmentStoreState environmentStoreState,
  required EnvironmentStore environmentStore,
  required BuildContext Function() context,
  required bool Function() mounted,
  required Environment Function() seedEnvironment,
  required ValueChanged<String> showMessage,
  required Future<void> Function() refreshActiveWorkspaceThumbnailIfNeeded,
  required Future<void> Function(String? path) storeLastEnvironmentPath,
  required Future<void> Function() syncWindowTitle,
  required Future<String?> Function(String bookmark) resolveFileBookmark,
  required Future<String?> Function(String path) createFileBookmark,
  required Future<Directory> Function() thumbnailDirectory,
  required ValueChanged<Environment> updateEnvironment,
  required Future<void> Function() saveEnvironment,
}) {
  return DocumentCoordinator(
    environmentStoreState: environmentStoreState,
    environmentStore: environmentStore,
    context: context,
    mounted: mounted,
    seedEnvironment: seedEnvironment,
    showMessage: showMessage,
    refreshActiveWorkspaceThumbnailIfNeeded: refreshActiveWorkspaceThumbnailIfNeeded,
    storeLastEnvironmentPath: storeLastEnvironmentPath,
    syncWindowTitle: syncWindowTitle,
    resolveFileBookmark: resolveFileBookmark,
    createFileBookmark: createFileBookmark,
    thumbnailDirectory: thumbnailDirectory,
    updateEnvironment: updateEnvironment,
    saveEnvironment: saveEnvironment,
  );
}

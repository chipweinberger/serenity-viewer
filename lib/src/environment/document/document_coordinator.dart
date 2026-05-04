import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/document/document_loader.dart' as document_loader;
import 'package:serenity_viewer/src/environment/document/document_saver.dart' as document_saver;
import 'package:serenity_viewer/src/environment/document/document_startup_prompter.dart' as document_startup_prompter;
import 'package:serenity_viewer/src/environment/document/document_thumbnail_restorer.dart'
    as document_thumbnail_restorer;
import 'package:serenity_viewer/src/environment/store/environment_store.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';

const suggestedDocumentName = 'serenity-enviroment';
const documentTypeGroups = [
  XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
];

class DocumentCoordinator {
  DocumentCoordinator({
    required this.environmentStoreState,
    required this.environmentStore,
    required this.context,
    required this.mounted,
    required this.seedEnvironment,
    required this.showMessage,
    required this.refreshActiveWorkspaceThumbnailIfNeeded,
    required this.storeLastEnvironmentPath,
    required this.syncWindowTitle,
    required this.resolveFileBookmark,
    required this.createFileBookmark,
    required this.thumbnailDirectory,
    required this.updateEnvironment,
    required this.saveEnvironment,
  });

  final EnvironmentStoreState environmentStoreState;
  final EnvironmentStore environmentStore;
  final BuildContext Function() context;
  final bool Function() mounted;
  final Environment Function() seedEnvironment;
  final ValueChanged<String> showMessage;
  final Future<void> Function() refreshActiveWorkspaceThumbnailIfNeeded;
  final Future<void> Function(String? path) storeLastEnvironmentPath;
  final Future<void> Function() syncWindowTitle;
  final Future<String?> Function(String bookmark) resolveFileBookmark;
  final Future<String?> Function(String path) createFileBookmark;
  final Future<Directory> Function() thumbnailDirectory;
  final ValueChanged<Environment> updateEnvironment;
  final Future<void> Function() saveEnvironment;

  Future<void> saveDocumentToPath(String path, {Environment? environmentOverride, bool showMessageOnFailure = true}) {
    return document_saver.saveDocumentToPath(
      this,
      path,
      environmentOverride: environmentOverride,
      showMessageOnFailure: showMessageOnFailure,
    );
  }

  Future<void> saveDocumentAs() {
    return document_saver.saveDocumentAs(this);
  }

  Future<void> saveDocument() {
    return document_saver.saveDocument(this);
  }

  Future<bool> openDocument({bool showSuccessMessage = true}) {
    return document_loader.openDocument(this, showSuccessMessage: showSuccessMessage);
  }

  Future<bool> loadDocumentFromPath(String path, {bool showSuccessMessage = true, bool persistAsLastOpened = true}) {
    return document_loader.loadDocumentFromPath(
      this,
      path,
      showSuccessMessage: showSuccessMessage,
      persistAsLastOpened: persistAsLastOpened,
    );
  }

  Future<bool> createDocument() {
    return document_loader.createDocument(this);
  }

  Future<void> promptForStartupDocument() {
    return document_startup_prompter.promptForStartupDocument(this);
  }

  Future<void> restoreDocumentThumbnails(Map<String, List<int>> thumbnailBytesByWorkspaceId, Environment environment) {
    return document_thumbnail_restorer.restoreDocumentThumbnails(
      this,
      thumbnailBytesByWorkspaceId,
      environment,
    );
  }
}

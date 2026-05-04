import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/session/environment_store.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/file_resolution/missing_asset_resolution.dart';
import 'package:serenity_viewer/src/environment/document/document_codec.dart';
import 'package:serenity_viewer/src/media/video/settings_and_video_models.dart';

part 'document_loader.dart';
part 'document_saver.dart';
part 'document_startup_prompter.dart';
part 'document_thumbnail_restorer.dart';

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
  }) : _loader = _DocumentLoader(),
       _saver = _DocumentSaver(),
       _startupPrompter = _DocumentStartupPrompter(),
       _thumbnailRestorer = _DocumentThumbnailRestorer();

  static const String _suggestedDocumentName = 'serenity-enviroment';
  static const List<XTypeGroup> _documentTypeGroups = [
    XTypeGroup(label: 'Serenity Environment', extensions: ['sry']),
  ];

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

  final _DocumentLoader _loader;
  final _DocumentSaver _saver;
  final _DocumentStartupPrompter _startupPrompter;
  final _DocumentThumbnailRestorer _thumbnailRestorer;

  Future<void> saveDocumentToPath(String path, {Environment? environmentOverride, bool showMessageOnFailure = true}) {
    return _saver.saveDocumentToPath(
      this,
      path,
      environmentOverride: environmentOverride,
      showMessageOnFailure: showMessageOnFailure,
    );
  }

  Future<void> saveDocumentAs() {
    return _saver.saveDocumentAs(this);
  }

  Future<void> saveDocument() {
    return _saver.saveDocument(this);
  }

  Future<bool> openDocument({bool showSuccessMessage = true}) {
    return _loader.openDocument(this, showSuccessMessage: showSuccessMessage);
  }

  Future<bool> loadDocumentFromPath(String path, {bool showSuccessMessage = true, bool persistAsLastOpened = true}) {
    return _loader.loadDocumentFromPath(
      this,
      path,
      showSuccessMessage: showSuccessMessage,
      persistAsLastOpened: persistAsLastOpened,
    );
  }

  Future<bool> createDocument() {
    return _loader.createDocument(this);
  }

  Future<void> promptForStartupDocument() {
    return _startupPrompter.promptForStartupDocument(this);
  }

  Future<void> restoreDocumentThumbnails(Map<String, List<int>> thumbnailBytesByWorkspaceId, Environment environment) {
    return _thumbnailRestorer.restoreDocumentThumbnails(this, thumbnailBytesByWorkspaceId, environment);
  }
}

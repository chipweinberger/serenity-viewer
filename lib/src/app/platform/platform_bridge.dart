import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/store/environment_store_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class PlatformBridge {
  PlatformBridge({
    required this.environmentStoreState,
    required this.isRunningInWidgetTest,
    required this.windowTitle,
    required this.showMessage,
    required this.isMounted,
  }) {
    if (!isRunningInWidgetTest && Platform.isMacOS) {
      dockImportChannel.setMethodCallHandler(_handleDockImportCall);
    }
  }

  final EnvironmentStoreState environmentStoreState;
  final bool isRunningInWidgetTest;
  final String Function() windowTitle;
  final void Function(String message) showMessage;
  final bool Function() isMounted;
  final _dockDroppedPathsController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get dockDroppedPaths => _dockDroppedPathsController.stream;

  Future<Directory> thumbnailDirectory() async {
    final environmentPath = environmentStoreState.currentEnvironmentPath ?? 'startup';
    final cacheKey = md5.convert(utf8.encode(environmentPath)).toString();
    final thumbnails = Directory('${Directory.systemTemp.path}/serenity-workspace-thumbnails/$cacheKey');
    await thumbnails.create(recursive: true);
    return thumbnails;
  }

  Future<String?> createFileBookmark(String path) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await bookmarkChannel.invokeMethod<String>('createBookmark', {'path': path});
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveFileBookmark(String bookmark) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await bookmarkChannel.invokeMethod<String>('resolveBookmark', {'bookmark': bookmark});
    } catch (_) {
      return null;
    }
  }

  Future<void> syncWindowTitle() async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      await windowChannel.invokeMethod<void>('setWindowTitle', {'title': windowTitle()});
    } catch (_) {
      // Ignore title updates if the platform hook is unavailable.
    }
  }

  Future<String?> loadLastEnvironmentPath() async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      return await preferencesChannel.invokeMethod<String>('getLastEnvironmentPath');
    } catch (_) {
      return null;
    }
  }

  Future<void> storeLastEnvironmentPath(String? path) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      if (path == null || path.isEmpty) {
        await preferencesChannel.invokeMethod<void>('clearLastEnvironmentPath');
      } else {
        await preferencesChannel.invokeMethod<void>('setLastEnvironmentPath', {'path': path});
      }
    } catch (_) {
      // Ignore preferences persistence failures.
    }
  }

  Future<void> revealAssetInFinder(Asset asset) async {
    final path = asset.filePath;
    if (path == null || path.isEmpty) {
      _showMessageIfMounted('That asset does not have a source file.');
      return;
    }

    if (!await File(path).exists()) {
      _showMessageIfMounted('That asset is missing its source file.');
      return;
    }

    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      final revealed = await fileActionsChannel.invokeMethod<bool>('revealInFinder', {'path': path});
      if (revealed == false) {
        _showMessageIfMounted('Serenity could not reveal that file in Finder.');
      }
    } catch (_) {
      _showMessageIfMounted('Serenity could not reveal that file in Finder.');
    }
  }

  Future<void> dispose() async {
    if (!isRunningInWidgetTest && Platform.isMacOS) {
      dockImportChannel.setMethodCallHandler(null);
    }
    await _dockDroppedPathsController.close();
  }

  Future<void> markDockImportReady() async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      await dockImportChannel.invokeMethod<void>('setDockImportReady');
    } catch (_) {
      // Ignore readiness handoff failures; Dock import just won't be available.
    }
  }

  Future<void> _handleDockImportCall(MethodCall call) async {
    if (call.method != 'importDockFiles') {
      throw MissingPluginException();
    }

    final arguments = call.arguments as Map<Object?, Object?>?;
    final rawPaths = arguments?['paths'] as List<Object?>? ?? const [];
    final paths = rawPaths.whereType<String>().where((path) => path.isNotEmpty).toList(growable: false);
    if (paths.isEmpty) {
      return;
    }

    _dockDroppedPathsController.add(paths);
  }

  void _showMessageIfMounted(String message) {
    if (!isMounted()) {
      return;
    }
    showMessage(message);
  }
}

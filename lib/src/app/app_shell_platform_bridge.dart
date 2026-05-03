import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:serenity_viewer/src/environments/session/shell_persistence_state.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

class AppShellPlatformBridge {
  AppShellPlatformBridge({
    required this.persistenceState,
    required this.isRunningInWidgetTest,
    required this.windowTitle,
  });

  final ShellPersistenceState persistenceState;
  final bool isRunningInWidgetTest;
  final String Function() windowTitle;

  Future<Directory> thumbnailDirectory() async {
    final environmentPath = persistenceState.currentEnvironmentPath ?? 'startup';
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
}

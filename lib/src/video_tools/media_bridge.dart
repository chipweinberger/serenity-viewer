import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/workspace_loading/media_load_plan.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/video_tools/settings_and_video_models.dart';
import 'package:serenity_viewer/src/environment/workspace_asset.dart';

@immutable
class SharedVideoState {
  const SharedVideoState({required this.controller, required this.initialization});

  final VideoPlayerController controller;
  final Future<void> initialization;
}

class MediaBridge {
  MediaBridge({required this.isRunningInWidgetTest, required this.showMessage, required this.isMounted});

  final bool isRunningInWidgetTest;
  final ValueChanged<String> showMessage;
  final ValueGetter<bool> isMounted;
  final Map<String, _SharedVideoControllerEntry> _sharedVideoControllers = {};

  SharedVideoState? sharedVideoForWindow(WorkspaceWindowState window, {required bool isLoaded}) {
    if (!isLoaded || window.asset.type != AssetType.video) {
      return null;
    }

    final path = window.asset.filePath;
    if (path == null || path.isEmpty) {
      return null;
    }

    final existing = _sharedVideoControllers[window.asset.id];
    if (existing != null) {
      if (existing.path == path) {
        return SharedVideoState(controller: existing.controller, initialization: existing.initialization);
      }
      _sharedVideoControllers.remove(window.asset.id);
      unawaited(existing.controller.dispose());
    }

    final controller = VideoPlayerController.file(File(path));
    final initialization = controller.initialize().then((_) async {
      await controller.setVolume(0);
      await controller.setLooping(true);
    });
    final entry = _SharedVideoControllerEntry(path: path, controller: controller, initialization: initialization);
    _sharedVideoControllers[window.asset.id] = entry;
    return SharedVideoState(controller: controller, initialization: initialization);
  }

  void syncSharedVideoControllers({required MediaLoadPlan loadPlan, required Environment? environment}) {
    if (environment == null) {
      return;
    }

    final retainedVideoIds = <String>{};
    for (final workspace in environment.workspaces) {
      for (final window in workspace.windows) {
        final path = window.asset.filePath;
        if (window.asset.type == AssetType.video &&
            loadPlan.loadedAssetIds.contains(window.asset.id) &&
            path != null &&
            path.isNotEmpty) {
          retainedVideoIds.add(window.asset.id);
        }
      }
    }

    final staleIds = _sharedVideoControllers.keys.where((id) => !retainedVideoIds.contains(id)).toList();
    for (final id in staleIds) {
      final removed = _sharedVideoControllers.remove(id);
      if (removed != null) {
        unawaited(removed.controller.dispose());
      }
    }
  }

  Future<String> md5ForFile(File file) async {
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<Size?> imageDimensionsForFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    } catch (_) {
      return null;
    }
  }

  Future<int?> videoDurationMsForFile(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration.inMilliseconds;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<VideoProbeResult?> probeVideoFile(File file) async {
    if (isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    try {
      final result = await videoToolsChannel.invokeMapMethod<String, dynamic>('probeVideo', {'path': file.path});
      if (result == null) {
        return null;
      }

      return VideoProbeResult(
        durationMs: (result['durationMs'] as num?)?.toInt(),
        width: (result['width'] as num?)?.toInt(),
        height: (result['height'] as num?)?.toInt(),
        frameCount: (result['frameCount'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> revealAssetInFinder(WorkspaceAsset asset) async {
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

  void dispose() {
    for (final entry in _sharedVideoControllers.values) {
      unawaited(entry.controller.dispose());
    }
    _sharedVideoControllers.clear();
  }

  void _showMessageIfMounted(String message) {
    if (!isMounted()) {
      return;
    }
    showMessage(message);
  }
}

class _SharedVideoControllerEntry {
  _SharedVideoControllerEntry({required this.path, required this.controller, required this.initialization});

  final String path;
  final VideoPlayerController controller;
  final Future<void> initialization;
}

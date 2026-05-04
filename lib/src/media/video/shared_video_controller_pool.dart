import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/media/loading/media_load_plan.dart';

@immutable
class SharedVideoState {
  const SharedVideoState({required this.controller, required this.initialization});

  final VideoPlayerController controller;
  final Future<void> initialization;
}

class SharedVideoControllerPool {
  final Map<String, _SharedVideoControllerEntry> _sharedVideoControllers = {};

  int? currentPositionMsForWindow(String windowId) {
    final controller = _sharedVideoControllers[windowId]?.controller;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    final durationMs = controller.value.duration.inMilliseconds;
    final positionMs = controller.value.position.inMilliseconds;
    if (durationMs <= 0) {
      return positionMs;
    }
    return positionMs.clamp(0, durationMs);
  }

  SharedVideoState? sharedVideoForWindow(Window window, {required bool isLoaded}) {
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

  void dispose() {
    for (final entry in _sharedVideoControllers.values) {
      unawaited(entry.controller.dispose());
    }
    _sharedVideoControllers.clear();
  }
}

class _SharedVideoControllerEntry {
  _SharedVideoControllerEntry({required this.path, required this.controller, required this.initialization});

  final String path;
  final VideoPlayerController controller;
  final Future<void> initialization;
}

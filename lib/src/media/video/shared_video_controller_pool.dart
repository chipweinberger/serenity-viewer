import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

@immutable
class SharedVideoState {
  const SharedVideoState({required this.controller, required this.initialization});

  final VideoPlayerController controller;
  final Future<void> initialization;
}

class SharedVideoControllerPool {
  static const Duration _controllerReleaseGrace = Duration(milliseconds: 350);

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

  SharedVideoState? sharedVideoForWindow(Window window, {required bool shouldCreate}) {
    if (window.asset.type != AssetType.video) {
      return null;
    }

    final path = window.asset.filePath;
    if (path == null || path.isEmpty) {
      return null;
    }

    final existing = _sharedVideoControllers[window.asset.id];
    if (existing != null) {
      if (existing.path == path) {
        if (shouldCreate) {
          existing.cancelPendingRelease();
        }
        if (shouldCreate || existing.isPendingRelease) {
          return SharedVideoState(controller: existing.controller, initialization: existing.initialization);
        }
        return null;
      }
      _disposeEntry(window.asset.id, existing);
    }

    if (!shouldCreate) {
      return null;
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

  void syncSharedVideoControllers({required Set<String> retainedVideoWindowIds}) {
    for (final entry in _sharedVideoControllers.entries) {
      if (retainedVideoWindowIds.contains(entry.key)) {
        entry.value.cancelPendingRelease();
        continue;
      }

      entry.value.scheduleRelease(
        after: _controllerReleaseGrace,
        onExpire: () => _disposeEntry(entry.key, entry.value),
      );
    }
  }

  void dispose() {
    for (final entry in _sharedVideoControllers.values) {
      entry.cancelPendingRelease();
      unawaited(entry.controller.dispose());
    }
    _sharedVideoControllers.clear();
  }

  void _disposeEntry(String windowId, _SharedVideoControllerEntry entry) {
    final current = _sharedVideoControllers[windowId];
    if (!identical(current, entry)) {
      return;
    }

    entry.cancelPendingRelease();
    _sharedVideoControllers.remove(windowId);
    unawaited(entry.controller.dispose());
  }
}

class _SharedVideoControllerEntry {
  _SharedVideoControllerEntry({required this.path, required this.controller, required this.initialization});

  final String path;
  final VideoPlayerController controller;
  final Future<void> initialization;
  Timer? _releaseTimer;

  bool get isPendingRelease => _releaseTimer != null;

  void cancelPendingRelease() {
    _releaseTimer?.cancel();
    _releaseTimer = null;
  }

  void scheduleRelease({required Duration after, required VoidCallback onExpire}) {
    if (_releaseTimer != null) {
      return;
    }

    _releaseTimer = Timer(after, () {
      _releaseTimer = null;
      onExpire();
    });
  }
}

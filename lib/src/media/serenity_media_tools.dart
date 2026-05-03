// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

class _SharedVideoControllerEntry {
  _SharedVideoControllerEntry({required this.path, required this.controller, required this.initialization});

  final String path;
  final VideoPlayerController controller;
  final Future<void> initialization;
}

extension _SerenityShellMediaTools on _SerenityShellState {
  _SharedVideoControllerEntry? _sharedVideoControllerForWindow(AssetWindowState window, {required bool isLoaded}) {
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
        return existing;
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
    return entry;
  }

  void _syncSharedVideoControllers(SerenityLoadPlan loadPlan) {
    final session = _session;
    if (session == null) {
      return;
    }

    final retainedVideoIds = <String>{};
    for (final workspace in session.workspaces) {
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

  Future<String> _md5ForFile(File file) async {
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<Size?> _imageDimensionsForFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    } catch (_) {
      return null;
    }
  }

  Future<int?> _videoDurationMsForFile(File file) async {
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

  Future<VideoProbeResult?> _probeVideoFile(File file) async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
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

  Future<void> _revealAssetInFinder(WorkspaceAsset asset) async {
    final path = asset.filePath;
    if (path == null || path.isEmpty) {
      _showMessage('That asset does not have a source file.');
      return;
    }

    if (!await File(path).exists()) {
      _showMessage('That asset is missing its source file.');
      return;
    }

    if (_isRunningInWidgetTest || !Platform.isMacOS) {
      return;
    }

    try {
      final revealed = await fileActionsChannel.invokeMethod<bool>('revealInFinder', {'path': path});
      if (revealed == false && mounted) {
        _showMessage('Serenity could not reveal that file in Finder.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Serenity could not reveal that file in Finder.');
      }
    }
  }

  Future<void> _showFocusedAssetInFinder() async {
    final focusedWindow = _focusedWindowOrNull();
    if (focusedWindow == null) {
      _showMessage('Focus a window first.');
      return;
    }
    await _revealAssetInFinder(focusedWindow.asset);
  }
}

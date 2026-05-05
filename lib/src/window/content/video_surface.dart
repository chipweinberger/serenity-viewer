import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/app/app_theme.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/window/content/zoom_box.dart';

class _PlaybackCoordinator {
  _PlaybackCoordinator({
    required this.onIntrinsicSizeResolved,
    required this.onPositionChanged,
    required this.shouldPersistPosition,
  });

  final ValueChanged<Size> onIntrinsicSizeResolved;
  final ValueChanged<int> onPositionChanged;
  final bool Function() shouldPersistPosition;

  VideoPlayerController? _controller;
  double? _reportedAspectRatio;
  int? _lastReportedPositionBucket;
  bool _isApplyingInitialPosition = false;

  void attach(VideoPlayerController controller) {
    if (_controller == controller) {
      return;
    }

    detach();
    _controller = controller;
    controller.addListener(_handleControllerTick);
  }

  void detach() {
    _controller?.removeListener(_handleControllerTick);
    _controller = null;
  }

  void resetReportedState() {
    _reportedAspectRatio = null;
    _lastReportedPositionBucket = null;
  }

  Duration? boundedPosition(Duration duration, int? positionMs) {
    if (positionMs == null || positionMs <= 0 || duration <= Duration.zero) {
      return null;
    }

    final maxMs = math.max(0, duration.inMilliseconds - 1);
    return Duration(milliseconds: positionMs.clamp(0, maxMs));
  }

  void reportPlaybackPosition(Duration position) {
    if (!shouldPersistPosition()) {
      return;
    }

    final bucket = (position.inMilliseconds / 100).round();
    if (_lastReportedPositionBucket == bucket) {
      return;
    }

    _lastReportedPositionBucket = bucket;
    onPositionChanged(bucket * 100);
  }

  void reportIntrinsicSize(VideoPlayerController controller) {
    final aspectRatio = controller.value.aspectRatio;
    final size = controller.value.size;
    if (aspectRatio <= 0 || size.width <= 0 || size.height <= 0 || _reportedAspectRatio == aspectRatio) {
      return;
    }

    _reportedAspectRatio = aspectRatio;
    onIntrinsicSizeResolved(size);
  }

  Future<void> syncToWidget({
    required Future<void> initialization,
    required VideoPlayerController controller,
    required int? positionMs,
    required bool isPaused,
    required double playbackSpeed,
    required bool forceSeek,
    required VoidCallback refreshUi,
  }) async {
    _isApplyingInitialPosition = true;
    try {
      await initialization;
      if (!controller.value.isInitialized) {
        return;
      }

      reportIntrinsicSize(controller);
      final targetPosition = boundedPosition(controller.value.duration, positionMs);
      if (targetPosition != null) {
        final deltaMs = (controller.value.position.inMilliseconds - targetPosition.inMilliseconds).abs();
        if (forceSeek || deltaMs > 150) {
          await controller.seekTo(targetPosition);
        }
      }

      if (isPaused) {
        await controller.pause();
      } else {
        await controller.play();
      }
      await controller.setPlaybackSpeed(playbackSpeed);

      reportPlaybackPosition(controller.value.position);
      refreshUi();
    } finally {
      _isApplyingInitialPosition = false;
    }
  }

  void dispose() {
    detach();
  }

  void _handleControllerTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isApplyingInitialPosition) {
      return;
    }

    reportIntrinsicSize(controller);
    reportPlaybackPosition(controller.value.position);
  }
}

class _PausedVideoFrame extends StatefulWidget {
  const _PausedVideoFrame({
    required this.path,
    required this.aspectRatio,
    required this.positionMs,
    required this.fallbackController,
    required this.zoom,
    required this.zoomBaseSize,
    required this.contentOffset,
  });

  final String path;
  final double aspectRatio;
  final int? positionMs;
  final VideoPlayerController? fallbackController;
  final double zoom;
  final Size? zoomBaseSize;
  final Offset contentOffset;

  @override
  State<_PausedVideoFrame> createState() => _PausedVideoFrameState();
}

class _PausedVideoFrameState extends State<_PausedVideoFrame> {
  Future<Uint8List?>? _thumbnailBytes;
  int? _thumbnailWidth;

  @override
  void didUpdateWidget(covariant _PausedVideoFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.positionMs != widget.positionMs) {
      _thumbnailBytes = null;
      _thumbnailWidth = null;
    }
  }

  Widget _buildFallbackFrame() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.12),
      child: const Center(child: Icon(Icons.play_circle_outline_rounded, size: 42, color: AppTheme.accent)),
    );
  }

  Widget _buildLoadingFrame() {
    final controller = widget.fallbackController;
    if (controller != null && controller.value.isInitialized) {
      return VideoPlayer(controller);
    }

    return _buildFallbackFrame();
  }

  Widget _buildThumbnailFrame(Uint8List bytes) {
    return SizedBox.expand(
      child: Image.memory(bytes, fit: BoxFit.fill, gaplessPlayback: true, filterQuality: FilterQuality.medium),
    );
  }

  Widget _buildResolvedFrame(AsyncSnapshot<Uint8List?> snapshot) {
    final thumbnailBytes = snapshot.data;
    if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
      return _buildLoadingFrame();
    }

    return Stack(fit: StackFit.expand, children: [_buildLoadingFrame(), _buildThumbnailFrame(thumbnailBytes)]);
  }

  Widget _buildThumbnailFuture(BuildContext context, BoxConstraints constraints) {
    _ensureThumbnail(_thumbnailWidthFor(constraints, context));
    return FutureBuilder<Uint8List?>(
      future: _thumbnailBytes,
      builder: (context, snapshot) {
        return ZoomBox(
          aspectRatio: widget.aspectRatio,
          zoom: widget.zoom,
          zoomBaseSize: widget.zoomBaseSize,
          contentOffset: widget.contentOffset,
          child: _buildResolvedFrame(snapshot),
        );
      },
    );
  }

  int _thumbnailWidthFor(BoxConstraints constraints, BuildContext context) {
    final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final logicalWidth = constraints.hasBoundedWidth && constraints.maxWidth > 0 ? constraints.maxWidth : 640.0;
    final physicalWidth = (logicalWidth * devicePixelRatio).round().clamp(320, 1920);
    return ((physicalWidth + 63) ~/ 64) * 64;
  }

  Future<Uint8List?> _renderThumbnailBytes(int targetWidth) async {
    if (!Platform.isMacOS) {
      return null;
    }

    try {
      return await videoToolsChannel.invokeMethod<Uint8List>('renderVideoThumbnail', {
        'sourcePath': widget.path,
        'positionMs': widget.positionMs ?? 0,
        'targetWidth': targetWidth,
      });
    } catch (_) {
      return null;
    }
  }

  void _ensureThumbnail(int targetWidth) {
    if (_thumbnailWidth == targetWidth && _thumbnailBytes != null) {
      return;
    }

    _thumbnailWidth = targetWidth;
    _thumbnailBytes = _renderThumbnailBytes(targetWidth);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildThumbnailFuture);
  }
}

class VideoSurface extends StatefulWidget {
  const VideoSurface({
    super.key,
    required this.controller,
    required this.initialization,
    required this.path,
    required this.aspectRatio,
    required this.zoom,
    required this.zoomBaseSize,
    required this.contentOffset,
    required this.onIntrinsicSizeResolved,
    required this.isPaused,
    required this.onTogglePlayback,
    required this.positionMs,
    required this.playbackSpeed,
    required this.onPositionChanged,
    required this.onCyclePlaybackSpeed,
    this.previewMode = false,
  });

  final VideoPlayerController? controller;
  final Future<void>? initialization;
  final String path;
  final double aspectRatio;
  final double zoom;
  final Size? zoomBaseSize;
  final Offset contentOffset;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final bool isPaused;
  final ValueChanged<int?> onTogglePlayback;
  final int? positionMs;
  final double playbackSpeed;
  final ValueChanged<int> onPositionChanged;
  final VoidCallback onCyclePlaybackSpeed;
  final bool previewMode;

  @override
  State<VideoSurface> createState() => _SerenityVideoSurfaceState();
}

class _SerenityVideoSurfaceState extends State<VideoSurface> {
  late final _PlaybackCoordinator _playbackCoordinator;
  int? _pausedThumbnailPositionMs;

  @override
  void initState() {
    super.initState();
    _playbackCoordinator = _PlaybackCoordinator(
      onIntrinsicSizeResolved: widget.onIntrinsicSizeResolved,
      onPositionChanged: widget.onPositionChanged,
      shouldPersistPosition: () => widget.isPaused,
    );
    _syncPausedThumbnailState();
    _syncPlaybackListener();
    unawaited(_syncControllerToWidget(forceSeek: true));
  }

  @override
  void didUpdateWidget(covariant VideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.controller != widget.controller ||
        oldWidget.isPaused != widget.isPaused) {
      _syncPausedThumbnailState();
    }

    if (oldWidget.controller != widget.controller || oldWidget.isPaused != widget.isPaused) {
      _syncPlaybackListener();
    }

    if (oldWidget.controller != widget.controller) {
      _playbackCoordinator.resetReportedState();
    }

    if (oldWidget.path != widget.path ||
        oldWidget.isPaused != widget.isPaused ||
        oldWidget.playbackSpeed != widget.playbackSpeed ||
        oldWidget.positionMs != widget.positionMs ||
        oldWidget.controller != widget.controller) {
      unawaited(
        _syncControllerToWidget(
          forceSeek:
              oldWidget.path != widget.path ||
              oldWidget.positionMs != widget.positionMs ||
              oldWidget.controller != widget.controller,
        ),
      );
    }
  }

  Future<void> _syncControllerToWidget({required bool forceSeek}) async {
    final controller = widget.controller;
    final initialization = widget.initialization;
    if (controller == null || initialization == null) {
      return;
    }

    await _playbackCoordinator.syncToWidget(
      initialization: initialization,
      controller: controller,
      positionMs: widget.positionMs,
      isPaused: widget.isPaused,
      playbackSpeed: widget.playbackSpeed,
      forceSeek: forceSeek,
      refreshUi: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    if (!mounted || !widget.isPaused || !controller.value.isInitialized) {
      return;
    }

    final pausedPositionMs = controller.value.position.inMilliseconds;
    if (_pausedThumbnailPositionMs == pausedPositionMs) {
      return;
    }

    setState(() {
      _pausedThumbnailPositionMs = pausedPositionMs;
    });
  }

  void _syncPlaybackListener() {
    final controller = widget.controller;
    if (controller == null || widget.isPaused) {
      _playbackCoordinator.detach();
      return;
    }

    _playbackCoordinator.attach(controller);
  }

  Widget _buildInitializedVideo(BuildContext context, VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) => ZoomBox(
        aspectRatio: controller.value.aspectRatio,
        zoom: widget.zoom,
        zoomBaseSize: widget.zoomBaseSize,
        contentOffset: widget.contentOffset,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildPausedVideo() {
    return _PausedVideoFrame(
      path: widget.path,
      aspectRatio: widget.aspectRatio,
      positionMs: _pausedThumbnailPositionMs ?? widget.positionMs,
      fallbackController: widget.controller,
      zoom: widget.zoom,
      zoomBaseSize: widget.zoomBaseSize,
      contentOffset: widget.contentOffset,
    );
  }

  bool get _shouldShowPausedThumbnail {
    return widget.controller == null || _pausedThumbnailPositionMs != null;
  }

  void _syncPausedThumbnailState() {
    if (!widget.isPaused) {
      _pausedThumbnailPositionMs = null;
      return;
    }

    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) {
      _pausedThumbnailPositionMs = widget.positionMs;
      return;
    }

    _pausedThumbnailPositionMs = null;
  }

  @override
  void dispose() {
    _playbackCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPaused) {
      if (!_shouldShowPausedThumbnail) {
        final controller = widget.controller;
        if (controller != null && controller.value.isInitialized) {
          return _buildInitializedVideo(context, controller);
        }
      }

      return _buildPausedVideo();
    }

    final controller = widget.controller;
    final initialization = widget.initialization;
    if (controller == null || initialization == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.value.isInitialized) {
      return _buildInitializedVideo(context, controller);
    }

    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !controller.value.isInitialized) {
          return const Center(child: Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.accent));
        }

        return _buildInitializedVideo(context, controller);
      },
    );
  }
}

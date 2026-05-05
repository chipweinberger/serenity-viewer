import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/app/app_theme.dart';
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

class VideoSurface extends StatefulWidget {
  const VideoSurface({
    super.key,
    required this.controller,
    required this.initialization,
    required this.path,
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

  final VideoPlayerController controller;
  final Future<void> initialization;
  final String path;
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

  @override
  void initState() {
    super.initState();
    _playbackCoordinator = _PlaybackCoordinator(
      onIntrinsicSizeResolved: widget.onIntrinsicSizeResolved,
      onPositionChanged: widget.onPositionChanged,
      shouldPersistPosition: () => widget.isPaused,
    );
    _playbackCoordinator.attach(widget.controller);
    unawaited(_syncControllerToWidget(forceSeek: true));
  }

  @override
  void didUpdateWidget(covariant VideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _playbackCoordinator.attach(widget.controller);
      _playbackCoordinator.resetReportedState();
      unawaited(_syncControllerToWidget(forceSeek: true));
      return;
    }

    if (oldWidget.path != widget.path ||
        oldWidget.isPaused != widget.isPaused ||
        oldWidget.playbackSpeed != widget.playbackSpeed) {
      unawaited(_syncControllerToWidget(forceSeek: oldWidget.path != widget.path));
    }
  }

  Future<void> _syncControllerToWidget({required bool forceSeek}) async {
    await _playbackCoordinator.syncToWidget(
      initialization: widget.initialization,
      controller: widget.controller,
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
  }

  @override
  void dispose() {
    _playbackCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.value.isInitialized) {
      return _buildInitializedVideo(context, widget.controller);
    }

    return FutureBuilder<void>(
      future: widget.initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !widget.controller.value.isInitialized) {
          return const Center(child: Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.accent));
        }

        return _buildInitializedVideo(context, widget.controller);
      },
    );
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
}

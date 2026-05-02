part of '../../main.dart';

class SerenityVideoSurface extends StatefulWidget {
  const SerenityVideoSurface({
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
    required this.showControls,
    required this.onControlInteractionChanged,
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
  final VoidCallback onTogglePlayback;
  final int? positionMs;
  final double playbackSpeed;
  final ValueChanged<int> onPositionChanged;
  final VoidCallback onCyclePlaybackSpeed;
  final bool showControls;
  final ValueChanged<bool> onControlInteractionChanged;
  final bool previewMode;

  @override
  State<SerenityVideoSurface> createState() => _SerenityVideoSurfaceState();
}

class _SerenityVideoSurfaceState extends State<SerenityVideoSurface> {
  double? _reportedAspectRatio;
  int? _lastReportedPositionBucket;
  bool _isApplyingInitialPosition = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerTick);
    unawaited(_syncControllerToWidget(forceSeek: true));
  }

  @override
  void didUpdateWidget(covariant SerenityVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerTick);
      widget.controller.addListener(_handleControllerTick);
      _reportedAspectRatio = null;
      _lastReportedPositionBucket = null;
      unawaited(_syncControllerToWidget(forceSeek: true));
      return;
    }

    if (oldWidget.path != widget.path ||
        oldWidget.isPaused != widget.isPaused ||
        oldWidget.playbackSpeed != widget.playbackSpeed) {
      unawaited(_syncControllerToWidget(forceSeek: oldWidget.path != widget.path));
    }
  }

  Duration? _boundedPosition(Duration duration, int? positionMs) {
    if (positionMs == null || positionMs <= 0 || duration <= Duration.zero) {
      return null;
    }
    final maxMs = math.max(0, duration.inMilliseconds - 1);
    return Duration(milliseconds: positionMs.clamp(0, maxMs));
  }

  String _playbackSpeedLabel(double speed) {
    if ((speed - 1.0).abs() < 0.001) {
      return '1.0x';
    }
    return '${speed.toString()}x';
  }

  void _handleControllerTick() {
    final controller = widget.controller;
    if (!controller.value.isInitialized || _isApplyingInitialPosition) {
      return;
    }
    _reportIntrinsicSize(controller);
    _reportPlaybackPosition(controller.value.position);
  }

  void _reportPlaybackPosition(Duration position) {
    final bucket = (position.inMilliseconds / 100).round();
    if (_lastReportedPositionBucket == bucket) {
      return;
    }
    _lastReportedPositionBucket = bucket;
    widget.onPositionChanged(bucket * 100);
  }

  void _reportIntrinsicSize(VideoPlayerController controller) {
    final aspectRatio = controller.value.aspectRatio;
    final size = controller.value.size;
    if (aspectRatio <= 0 || size.width <= 0 || size.height <= 0 || _reportedAspectRatio == aspectRatio) {
      return;
    }

    _reportedAspectRatio = aspectRatio;
    widget.onIntrinsicSizeResolved(size);
  }

  Future<void> _syncControllerToWidget({required bool forceSeek}) async {
    _isApplyingInitialPosition = true;
    try {
      await widget.initialization;
      final controller = widget.controller;
      if (!controller.value.isInitialized) {
        return;
      }

      _reportIntrinsicSize(controller);
      final targetPosition = _boundedPosition(controller.value.duration, widget.positionMs);
      if (targetPosition != null) {
        final deltaMs = (controller.value.position.inMilliseconds - targetPosition.inMilliseconds).abs();
        if (forceSeek || deltaMs > 150) {
          await controller.seekTo(targetPosition);
        }
      }

      if (widget.isPaused) {
        await controller.pause();
      } else {
        await controller.play();
      }
      await controller.setPlaybackSpeed(widget.playbackSpeed);

      _reportPlaybackPosition(controller.value.position);
      if (mounted) {
        setState(() {});
      }
    } finally {
      _isApplyingInitialPosition = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerTick);
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
          return const Center(child: Icon(Icons.error_outline_rounded, size: 40, color: SerenityTheme.accent));
        }

        return _buildInitializedVideo(context, widget.controller);
      },
    );
  }

  Widget _buildInitializedVideo(BuildContext context, VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final durationMs = value.duration.inMilliseconds;
        final positionMs = value.position.inMilliseconds.clamp(0, durationMs <= 0 ? 0 : durationMs);
        final elapsedLabel = _formatDuration(value.position);
        final totalLabel = _formatDuration(value.duration);
        final speedLabel = _playbackSpeedLabel(widget.playbackSpeed);

        return Stack(
          fit: StackFit.expand,
          children: [
            SerenityZoomBox(
              aspectRatio: controller.value.aspectRatio,
              zoom: widget.zoom,
              zoomBaseSize: widget.zoomBaseSize,
              contentOffset: widget.contentOffset,
              child: VideoPlayer(controller),
            ),
            if (widget.showControls && durationMs > 0)
              Positioned(
                left: 10,
                right: 10,
                bottom: 42,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$elapsedLabel / $totalLabel',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.42),
                              child: InkWell(
                                onTap: widget.onCyclePlaybackSpeed,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: Text(
                                    speedLabel,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Row(
                        children: [
                          ClipOval(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.42),
                                child: InkWell(
                                  onTap: widget.onTogglePlayback,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      widget.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Listener(
                                    onPointerDown: (_) => widget.onControlInteractionChanged(true),
                                    onPointerUp: (_) => widget.onControlInteractionChanged(false),
                                    onPointerCancel: (_) => widget.onControlInteractionChanged(false),
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white.withValues(alpha: 0.28),
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.white.withValues(alpha: 0.14),
                                      ),
                                      child: Slider(
                                        value: positionMs.toDouble().clamp(0, durationMs.toDouble()),
                                        min: 0,
                                        max: durationMs.toDouble(),
                                        onChanged: (nextValue) async {
                                          await widget.controller.seekTo(Duration(milliseconds: nextValue.round()));
                                        },
                                        onChangeEnd: (_) => widget.onControlInteractionChanged(false),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

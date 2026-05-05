import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';

class WindowOverlay extends StatelessWidget {
  const WindowOverlay({
    super.key,
    required this.windowSize,
    required this.workspaceZoom,
    required this.filename,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onShowInFinder,
    required this.onClose,
    this.onFitToContent,
    this.onRestorePreviousZOrder,
    required this.assetType,
    required this.sharedVideoController,
    required this.sharedVideoInitialization,
    required this.isVideoPaused,
    required this.videoPositionMs,
    required this.playbackSpeed,
    required this.showVideoControls,
    required this.showPausedPlaybackButton,
    required this.onVideoControlInteractionChanged,
    required this.onVideoPositionChanged,
    required this.onCycleVideoPlaybackSpeed,
    required this.onTogglePlayback,
  });

  final Size windowSize;
  final double workspaceZoom;
  final String filename;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback? onShowInFinder;
  final VoidCallback onClose;
  final VoidCallback? onFitToContent;
  final VoidCallback? onRestorePreviousZOrder;
  final AssetType assetType;
  final VideoPlayerController? sharedVideoController;
  final Future<void>? sharedVideoInitialization;
  final bool isVideoPaused;
  final int? videoPositionMs;
  final double playbackSpeed;
  final bool showVideoControls;
  final bool showPausedPlaybackButton;
  final ValueChanged<bool> onVideoControlInteractionChanged;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;
  final ValueChanged<int?> onTogglePlayback;

  double get _uiScale {
    final safeZoom = workspaceZoom <= 0 ? 1.0 : workspaceZoom;
    return (1 / safeZoom).clamp(0.25, 1.2);
  }

  bool get _showsAnyVideoControl {
    return assetType == AssetType.video && (showVideoControls || showPausedPlaybackButton);
  }

  @override
  Widget build(BuildContext context) {
    final uiScale = _uiScale;
    final metrics = _WindowOverlayMetrics(uiScale: uiScale, showsVideoControls: _showsAnyVideoControl);
    final layoutMode = metrics.layoutModeForWindow(windowSize);
    final titleStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12 * uiScale);

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(metrics.edgeInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (layoutMode != _WindowOverlayLayoutMode.closeOnly) ...[
                  _buildSelectButton(metrics),
                  if (layoutMode == _WindowOverlayLayoutMode.full) ...[
                    SizedBox(width: metrics.controlGap),
                    Expanded(
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: onShowInFinder,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.titleHorizontal,
                              vertical: metrics.titleVertical,
                            ),
                            child: Text(filename, overflow: TextOverflow.ellipsis, style: titleStyle),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.controlGap),
                  ],
                ],
                if (layoutMode != _WindowOverlayLayoutMode.full) const Spacer(),
                _buildCloseButton(metrics),
              ],
            ),
            const Spacer(),
            if (layoutMode == _WindowOverlayLayoutMode.full && _showsAnyVideoControl) ...[
              _WindowVideoControls(
                controller: sharedVideoController,
                initialization: sharedVideoInitialization,
                isPaused: isVideoPaused,
                positionMs: videoPositionMs,
                playbackSpeed: playbackSpeed,
                uiScale: uiScale,
                showControls: showVideoControls,
                showPausedPlaybackButton: showPausedPlaybackButton,
                onControlInteractionChanged: onVideoControlInteractionChanged,
                onPositionChanged: onVideoPositionChanged,
                onCyclePlaybackSpeed: onCycleVideoPlaybackSpeed,
                onTogglePlayback: onTogglePlayback,
              ),
              SizedBox(height: metrics.bottomGap),
            ],
            if (layoutMode != _WindowOverlayLayoutMode.closeOnly)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onFitToContent != null) ...[
                    Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: onFitToContent,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: EdgeInsets.all(metrics.smallActionSize),
                          child: Icon(Icons.fit_screen_rounded, size: metrics.bottomIconSize, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.bottomGap),
                  ],
                  Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onRestorePreviousZOrder,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: EdgeInsets.all(metrics.smallActionSize),
                        child: Icon(Icons.flip_to_back_rounded, size: metrics.bottomIconSize, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectButton(_WindowOverlayMetrics metrics) {
    return Material(
      color: isSelected ? const Color(0xFF3B82F6) : Colors.black.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onToggleSelected,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.all(metrics.selectSize),
          child: Icon(
            isSelected ? Icons.check_rounded : Icons.circle_outlined,
            size: metrics.iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(_WindowOverlayMetrics metrics) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onClose,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.all(metrics.closeSize),
          child: Icon(Icons.close_rounded, size: metrics.iconSize, color: Colors.white),
        ),
      ),
    );
  }
}

class _WindowOverlayMetrics {
  const _WindowOverlayMetrics({required this.uiScale, required this.showsVideoControls});

  final double uiScale;
  final bool showsVideoControls;

  double get edgeInset => 10.0 * uiScale;
  double get selectSize => 7.0 * uiScale;
  double get closeSize => 8.0 * uiScale;
  double get smallActionSize => 7.0 * uiScale;
  double get iconSize => 16.0 * uiScale;
  double get bottomIconSize => 14.0 * uiScale;
  double get controlGap => 8.0 * uiScale;
  double get bottomGap => 6.0 * uiScale;
  double get titleVertical => 7.0 * uiScale;
  double get titleHorizontal => 10.0 * uiScale;
  double get minTitleWidth => 72.0 * uiScale;
  double get minVideoControlsWidth => 132.0 * uiScale;
  double get topButtonDiameter => (selectSize * 2) + iconSize;
  double get closeButtonDiameter => (closeSize * 2) + iconSize;
  double get bottomButtonDiameter => (smallActionSize * 2) + bottomIconSize;
  double get topRowHeight => topButtonDiameter;
  double get bottomRowWidth => bottomButtonDiameter * 2 + bottomGap;
  double get bottomRowHeight => bottomButtonDiameter;
  double get videoControlsHeight => 62.0 * uiScale;
  double get videoControlsBlockHeight => showsVideoControls ? videoControlsHeight + bottomGap : 0;
  double get compactTopRowWidth => (edgeInset * 2) + topButtonDiameter + controlGap + closeButtonDiameter;
  double get compactMinHeight => (edgeInset * 2) + topRowHeight + bottomRowHeight + 24.0;
  double get closeOnlyMinWidth => (edgeInset * 2) + closeButtonDiameter;
  double get closeOnlyMinHeight => (edgeInset * 2) + closeButtonDiameter;

  double get minFullWidth {
    final topRowWidth =
        (edgeInset * 2) + topButtonDiameter + controlGap + minTitleWidth + controlGap + closeButtonDiameter;
    final minBottomWidth = (edgeInset * 2) + bottomRowWidth;
    final minVideoWidth = showsVideoControls ? (edgeInset * 2) + minVideoControlsWidth : 0;
    return [topRowWidth, minBottomWidth, minVideoWidth].reduce((a, b) => a > b ? a : b).toDouble();
  }

  double get minFullHeight => (edgeInset * 2) + topRowHeight + bottomRowHeight + videoControlsBlockHeight + 24.0;

  _WindowOverlayLayoutMode layoutModeForWindow(Size size) {
    final canRenderFullOverlay = size.width >= minFullWidth && size.height >= minFullHeight;
    if (canRenderFullOverlay) {
      return _WindowOverlayLayoutMode.full;
    }

    final canRenderCompactOverlay = size.width >= compactTopRowWidth && size.height >= compactMinHeight;
    if (canRenderCompactOverlay) {
      return _WindowOverlayLayoutMode.compact;
    }

    final canRenderCloseOnly = size.width >= closeOnlyMinWidth && size.height >= closeOnlyMinHeight;
    if (canRenderCloseOnly) {
      return _WindowOverlayLayoutMode.closeOnly;
    }

    return _WindowOverlayLayoutMode.closeOnly;
  }
}

enum _WindowOverlayLayoutMode { full, compact, closeOnly }

class _WindowVideoControls extends StatelessWidget {
  const _WindowVideoControls({
    required this.controller,
    required this.initialization,
    required this.isPaused,
    required this.positionMs,
    required this.playbackSpeed,
    required this.uiScale,
    required this.showControls,
    required this.showPausedPlaybackButton,
    required this.onControlInteractionChanged,
    required this.onPositionChanged,
    required this.onCyclePlaybackSpeed,
    required this.onTogglePlayback,
  });

  final VideoPlayerController? controller;
  final Future<void>? initialization;
  final bool isPaused;
  final int? positionMs;
  final double playbackSpeed;
  final double uiScale;
  final bool showControls;
  final bool showPausedPlaybackButton;
  final ValueChanged<bool> onControlInteractionChanged;
  final ValueChanged<int> onPositionChanged;
  final VoidCallback onCyclePlaybackSpeed;
  final ValueChanged<int?> onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    final videoController = controller;
    if (videoController == null) {
      return _buildFallbackPlaybackButton();
    }

    if (videoController.value.isInitialized) {
      return _buildForController(context, videoController);
    }

    final future = initialization;
    if (future == null) {
      return _buildFallbackPlaybackButton();
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !videoController.value.isInitialized) {
          return _buildFallbackPlaybackButton();
        }
        return _buildForController(context, videoController);
      },
    );
  }

  Widget _buildFallbackPlaybackButton() {
    if (!showPausedPlaybackButton || !isPaused) {
      return const SizedBox.shrink();
    }

    return _buildPlaybackButton(
      uiScale: uiScale,
      icon: Icons.play_arrow_rounded,
      padding: 4 * uiScale,
      iconSize: 12 * uiScale,
      positionMs: positionMs ?? 0,
    );
  }

  Widget _buildForController(BuildContext context, VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final durationMs = value.duration.inMilliseconds;
        if (durationMs <= 0) {
          return const SizedBox.shrink();
        }

        final currentPositionMs = value.position.inMilliseconds.clamp(0, durationMs);
        final elapsedLabel = _formatDuration(value.position);
        final totalLabel = _formatDuration(value.duration);
        final speedLabel = _playbackSpeedLabel(playbackSpeed);

        if (showControls) {
          return _buildControlsColumn(
            context,
            controller: controller,
            positionMs: currentPositionMs,
            durationMs: durationMs,
            elapsedLabel: elapsedLabel,
            totalLabel: totalLabel,
            speedLabel: speedLabel,
            uiScale: uiScale,
          );
        }

        if (showPausedPlaybackButton && isPaused) {
          return _buildPlaybackButton(
            uiScale: uiScale,
            icon: Icons.play_arrow_rounded,
            padding: 4 * uiScale,
            iconSize: 12 * uiScale,
            positionMs: currentPositionMs,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildControlsColumn(
    BuildContext context, {
    required VideoPlayerController controller,
    required int positionMs,
    required int durationMs,
    required String elapsedLabel,
    required String totalLabel,
    required String speedLabel,
    required double uiScale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPill(
              uiScale: uiScale,
              child: Text(
                '$elapsedLabel / $totalLabel',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  fontSize: 11 * uiScale,
                ),
              ),
            ),
            SizedBox(width: 6 * uiScale),
            _buildPill(
              uiScale: uiScale,
              onTap: onCyclePlaybackSpeed,
              child: Text(
                speedLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  fontSize: 11 * uiScale,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * uiScale),
        Row(
          children: [
            _buildPlaybackButton(
              uiScale: uiScale,
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              padding: 6 * uiScale,
              iconSize: 14 * uiScale,
              positionMs: positionMs,
            ),
            SizedBox(width: 8 * uiScale),
            Expanded(
              child: _buildPill(
                uiScale: uiScale,
                padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 2 * uiScale),
                child: Listener(
                  onPointerDown: (_) => onControlInteractionChanged(true),
                  onPointerUp: (_) => onControlInteractionChanged(false),
                  onPointerCancel: (_) => onControlInteractionChanged(false),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3 * uiScale,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6 * uiScale),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12 * uiScale),
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
                        final nextPosition = nextValue.round();
                        onPositionChanged(nextPosition);
                        await controller.seekTo(Duration(milliseconds: nextPosition));
                      },
                      onChangeEnd: (_) => onControlInteractionChanged(false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPill({
    required double uiScale,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
  }) {
    final content = Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 4 * uiScale),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12 * uiScale, sigmaY: 12 * uiScale),
        child: Material(
          color: Colors.black.withValues(alpha: 0.42),
          child: onTap == null ? content : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }

  Widget _buildPlaybackButton({
    required double uiScale,
    required IconData icon,
    required double padding,
    required double iconSize,
    required int positionMs,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12 * uiScale, sigmaY: 12 * uiScale),
        child: Material(
          color: Colors.black.withValues(alpha: 0.42),
          child: InkWell(
            onTap: () => onTogglePlayback(positionMs),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Icon(icon, size: iconSize, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  String _playbackSpeedLabel(double speed) {
    if ((speed - 1.0).abs() < 0.001) {
      return '1.0x';
    }
    return '${speed.toString()}x';
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

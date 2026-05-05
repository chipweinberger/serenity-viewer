import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/app/app_theme.dart';
import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/window/content/demo_art_widget.dart';

class MissingMediaPlaceholder extends StatelessWidget {
  const MissingMediaPlaceholder({
    super.key,
    required this.asset,
    required this.filename,
    required this.windowSize,
    required this.compact,
  });

  final Asset asset;
  final String filename;
  final Size windowSize;
  final bool compact;

  static const _missingIcon = Icons.location_searching_rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DemoArtWidget(asset: asset),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: compact ? 10 : 18, sigmaY: compact ? 10 : 18),
              child: ColoredBox(color: Colors.black.withValues(alpha: compact ? 0.48 : 0.58)),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 16 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? math.min(windowSize.width * 0.8, 220) : 380),
                  child: _buildMissingContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingContent(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800);
    final filenameStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.3);
    final detailStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8), height: 1.4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_missingIcon, size: compact ? 40 : 48, color: Colors.white),
        SizedBox(height: compact ? 10 : 14),
        Text('File missing', textAlign: TextAlign.center, style: titleStyle),
        SizedBox(height: compact ? 6 : 8),
        Text(
          filename,
          textAlign: TextAlign.center,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: filenameStyle,
        ),
        if (!compact) ...[
          const SizedBox(height: 10),
          Text(
            'Serenity will keep trying known folders when the session loads again.',
            textAlign: TextAlign.center,
            style: detailStyle,
          ),
        ],
      ],
    );
  }
}

class UnloadedMediaPlaceholder extends StatelessWidget {
  const UnloadedMediaPlaceholder({super.key, required this.asset, required this.windowSize});

  final Asset asset;
  final Size windowSize;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = switch (asset.videoLengthCategory) {
      VideoLengthCategory.short => 'Short video',
      VideoLengthCategory.long => 'Long video',
      null => asset.type == AssetType.image ? 'Image' : 'Video',
    };

    return Center(
      child: Container(
        width: math.min(windowSize.width * 0.74, 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.accent),
            const SizedBox(height: 14),
            Text(
              'Temporarily unloaded',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              asset.filename,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '$categoryLabel was parked to stay inside the current loaded-asset limits. It will load again when its workspace becomes active.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoLoadPlaceholder extends StatelessWidget {
  const VideoLoadPlaceholder({
    super.key,
    required this.asset,
    required this.windowSize,
    required this.compact,
    required this.onLoadVideos,
  });

  final Asset asset;
  final Size windowSize;
  final bool compact;
  final VoidCallback onLoadVideos;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DemoArtWidget(asset: asset),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: compact ? 10 : 18, sigmaY: compact ? 10 : 18),
              child: ColoredBox(color: Colors.black.withValues(alpha: compact ? 0.46 : 0.56)),
            ),
            if (compact)
              const Center(child: Icon(Icons.video_library_rounded, size: 40, color: Colors.white))
            else
              Padding(
                padding: const EdgeInsets.all(28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.video_library_rounded, size: 48, color: Colors.white),
                              const SizedBox(height: 38),
                              FilledButton.tonal(
                                onPressed: onLoadVideos,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                                child: const Text('Load videos'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

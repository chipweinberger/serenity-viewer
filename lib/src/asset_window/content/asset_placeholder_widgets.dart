import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/environment/workspace_asset.dart';

class MissingMediaPlaceholder extends StatelessWidget {
  const MissingMediaPlaceholder({super.key, required this.filename, required this.windowSize, required this.compact});

  final String filename;
  final Size windowSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Center(child: Icon(Icons.location_searching_rounded, size: 44, color: Colors.white));
    }

    return SizedBox.expand(
      child: ClipRect(
        child: OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          alignment: Alignment.center,
          child: Container(
            width: math.min(windowSize.width * 0.74, 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_searching_rounded, size: 48, color: AppTheme.accent),
                const SizedBox(height: 14),
                Text(
                  'File missing',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  filename,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Serenity will keep trying known folders when the session loads again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UnloadedMediaPlaceholder extends StatelessWidget {
  const UnloadedMediaPlaceholder({super.key, required this.asset, required this.windowSize});

  final WorkspaceAsset asset;
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/media/loading/workspace_media_counts.dart';

class ThumbnailCard extends StatefulWidget {
  const ThumbnailCard({
    super.key,
    required this.workspace,
    required this.mediaCounts,
    required this.unloadedCount,
    required this.hoverActions,
    this.onTap,
    this.isRefreshing = false,
    this.isDimmed = false,
    this.statusLabel,
  });

  final Workspace workspace;
  final WorkspaceMediaCounts mediaCounts;
  final int unloadedCount;
  final List<Widget> hoverActions;
  final VoidCallback? onTap;
  final bool isRefreshing;
  final bool isDimmed;
  final String? statusLabel;

  @override
  State<ThumbnailCard> createState() => _ThumbnailCardState();
}

class _ThumbnailCardState extends State<ThumbnailCard> {
  bool _isHovered = false;

  Widget _buildEmptyWorkspace(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 26, color: AppTheme.textMuted.withValues(alpha: 0.8)),
            const SizedBox(height: 8),
            Text(
              'Empty workspace',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textPrimary.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(
    List<Color> previewColors,
    bool hasThumbnail,
    String? thumbnailPath,
    Workspace workspace,
  ) {
    if (workspace.windows.isEmpty) {
      return _buildEmptyWorkspace(context);
    }

    if (hasThumbnail) {
      return Image(
        key: ValueKey('${workspace.id}:${workspace.thumbnailVersion}'),
        image: FileImage(File(thumbnailPath!)),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return ColoredBox(color: const Color(0xFFF3EBDD), child: child);
        },
        errorBuilder: (context, error, stackTrace) => _buildPreviewFallback(previewColors),
      );
    }

    return _buildPreviewFallback(previewColors);
  }

  Widget _buildPreviewFallback(List<Color> previewColors) {
    return Stack(
      children: [
        if (previewColors.isNotEmpty) _buildPreviewSwatch(previewColors.first, Alignment.centerLeft),
        if (previewColors.length > 1) _buildPreviewSwatch(previewColors[1], Alignment.center),
        if (previewColors.length > 2) _buildPreviewSwatch(previewColors[2], Alignment.centerRight),
      ],
    );
  }

  Widget _buildPreviewSwatch(Color color, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 90,
        height: 66,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  Widget _buildFooterMetric(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 1),
          child: Icon(icon, size: 13, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.textMuted, height: 1.0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = widget.workspace;
    final previewColors = workspace.windows.take(3).map((window) => window.asset.color.withValues(alpha: 0.8)).toList();
    final thumbnailPath = workspace.thumbnailPath;
    final hasThumbnail = thumbnailPath != null && File(thumbnailPath).existsSync();
    final mediaCounts = widget.mediaCounts;
    final statusLabel = widget.statusLabel;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppTheme.shadow.withValues(alpha: 0.24), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(color: Color(0xFFF3EBDD)),
                            child: widget.isDimmed
                                ? ColorFiltered(
                                    colorFilter: const ColorFilter.matrix(<double>[
                                      0.55,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0.55,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0.55,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      1,
                                      0,
                                    ]),
                                    child: _buildPreviewContent(previewColors, hasThumbnail, thumbnailPath, workspace),
                                  )
                                : _buildPreviewContent(previewColors, hasThumbnail, thumbnailPath, workspace),
                          ),
                        ),
                        if (widget.isDimmed)
                          Positioned.fill(
                            child: DecoratedBox(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18))),
                          ),
                        if (statusLabel != null)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Text(
                                  statusLabel,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        if (widget.isRefreshing)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.34),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IgnorePointer(
                            ignoring: !_isHovered,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              opacity: _isHovered ? 1 : 0,
                              child: Row(children: widget.hoverActions),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workspace.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${workspace.windows.length} windows',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              _buildFooterMetric(context, Icons.photo_library_outlined, '${mediaCounts.total} media'),
                              if (widget.unloadedCount > 0)
                                _buildFooterMetric(
                                  context,
                                  Icons.downloading_rounded,
                                  '${widget.unloadedCount} pending',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

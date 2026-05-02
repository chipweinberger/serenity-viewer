part of '../../main.dart';

class WorkspaceThumbnailCard extends StatefulWidget {
  const WorkspaceThumbnailCard({
    super.key,
    required this.workspace,
    required this.mediaCounts,
    required this.unloadedCount,
    required this.hoverActions,
    required this.onTap,
    this.isRefreshing = false,
  });

  final WorkspaceState workspace;
  final WorkspaceMediaCounts mediaCounts;
  final int unloadedCount;
  final List<Widget> hoverActions;
  final VoidCallback onTap;
  final bool isRefreshing;

  @override
  State<WorkspaceThumbnailCard> createState() => _WorkspaceThumbnailCardState();
}

class _WorkspaceThumbnailCardState extends State<WorkspaceThumbnailCard> {
  bool _isHovered = false;

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
          child: Icon(icon, size: 13, color: SerenityTheme.textMuted),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: SerenityTheme.textMuted, height: 1.0),
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: SerenityTheme.panel,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: SerenityTheme.shadow, blurRadius: 16, offset: Offset(0, 8))],
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
                            child: hasThumbnail
                                ? Image(
                                    key: ValueKey('${workspace.id}:${workspace.thumbnailVersion}'),
                                    image: FileImage(File(thumbnailPath)),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                      if (wasSynchronouslyLoaded || frame != null) {
                                        return child;
                                      }
                                      return ColoredBox(color: const Color(0xFFF3EBDD), child: child);
                                    },
                                    errorBuilder: (context, error, stackTrace) => Stack(
                                      children: [
                                        if (previewColors.isNotEmpty)
                                          _buildPreviewSwatch(previewColors.first, Alignment.centerLeft),
                                        if (previewColors.length > 1)
                                          _buildPreviewSwatch(previewColors[1], Alignment.center),
                                        if (previewColors.length > 2)
                                          _buildPreviewSwatch(previewColors[2], Alignment.centerRight),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      if (previewColors.isNotEmpty)
                                        _buildPreviewSwatch(previewColors.first, Alignment.centerLeft),
                                      if (previewColors.length > 1)
                                        _buildPreviewSwatch(previewColors[1], Alignment.center),
                                      if (previewColors.length > 2)
                                        _buildPreviewSwatch(previewColors[2], Alignment.centerRight),
                                    ],
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
                        if (_isHovered && widget.hoverActions.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(mainAxisSize: MainAxisSize.min, children: widget.hoverActions),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 8, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          workspace.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: SerenityTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        DefaultTextStyle(
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium!.copyWith(color: SerenityTheme.textMuted, height: 1.0),
                          child: Row(
                            children: [
                              _buildFooterMetric(context, Icons.visibility_outlined, '${workspace.views}'),
                              const SizedBox(width: 8),
                              _buildFooterMetric(context, Icons.image_outlined, '${mediaCounts.images}'),
                              const SizedBox(width: 8),
                              _buildFooterMetric(context, Icons.videocam_outlined, '${mediaCounts.videos}'),
                              const SizedBox(width: 8),
                              _buildFooterMetric(context, Icons.link_rounded, '${mediaCounts.links}'),
                              if (widget.unloadedCount > 0) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _buildFooterMetric(
                                    context,
                                    Icons.cloud_off_outlined,
                                    '${widget.unloadedCount}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

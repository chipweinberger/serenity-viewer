part of '../../main.dart';

class _SerenityWindowOverlay extends StatelessWidget {
  const _SerenityWindowOverlay({
    required this.workspaceZoom,
    required this.filename,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onShowInFinder,
    required this.onClose,
    this.onFitToContent,
    this.onRestorePreviousZOrder,
  });

  final double workspaceZoom;
  final String filename;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback? onShowInFinder;
  final VoidCallback onClose;
  final VoidCallback? onFitToContent;
  final VoidCallback? onRestorePreviousZOrder;

  double get _uiScale {
    final safeZoom = workspaceZoom <= 0 ? 1.0 : workspaceZoom;
    return (1 / safeZoom).clamp(0.85, 2.1);
  }

  @override
  Widget build(BuildContext context) {
    final uiScale = _uiScale;
    final edgeInset = 10.0 * uiScale;
    final selectSize = 7.0 * uiScale;
    final closeSize = 8.0 * uiScale;
    final smallActionSize = 7.0 * uiScale;
    final iconSize = 16.0 * uiScale;
    final bottomIconSize = 14.0 * uiScale;
    final controlGap = 8.0 * uiScale;
    final bottomGap = 6.0 * uiScale;
    final titleLeft = edgeInset + (34.0 * uiScale);
    final titleVertical = 7.0 * uiScale;
    final titleHorizontal = 10.0 * uiScale;
    final titleStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12 * uiScale);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              top: edgeInset,
              left: edgeInset,
              child: Material(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onToggleSelected,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: EdgeInsets.all(selectSize),
                    child: Icon(
                      isSelected ? Icons.check_rounded : Icons.circle_outlined,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: edgeInset,
              left: titleLeft,
              right: edgeInset,
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: onShowInFinder,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: titleHorizontal, vertical: titleVertical),
                          child: Text(filename, overflow: TextOverflow.ellipsis, style: titleStyle),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: controlGap),
                  Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: EdgeInsets.all(closeSize),
                        child: Icon(Icons.close_rounded, size: iconSize, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: edgeInset,
              bottom: edgeInset,
              child: Row(
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
                          padding: EdgeInsets.all(smallActionSize),
                          child: Icon(Icons.fit_screen_rounded, size: bottomIconSize, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: bottomGap),
                  ],
                  Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onRestorePreviousZOrder,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: EdgeInsets.all(smallActionSize),
                        child: Icon(Icons.flip_to_back_rounded, size: bottomIconSize, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

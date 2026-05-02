part of '../../main.dart';

class _SerenityWindowOverlay extends StatelessWidget {
  const _SerenityWindowOverlay({
    required this.filename,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onShowInFinder,
    required this.onClose,
    this.onFitToContent,
    this.onRestorePreviousZOrder,
  });

  final String filename;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback? onShowInFinder;
  final VoidCallback onClose;
  final VoidCallback? onFitToContent;
  final VoidCallback? onRestorePreviousZOrder;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Material(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onToggleSelected,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      isSelected ? Icons.check_rounded : Icons.circle_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 44,
              right: 10,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            filename,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
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
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.fit_screen_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: onRestorePreviousZOrder,
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(Icons.flip_to_back_rounded, size: 14, color: Colors.white),
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

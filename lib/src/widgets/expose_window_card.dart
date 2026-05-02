part of '../../main.dart';

class ExposeWindowCard extends StatefulWidget {
  const ExposeWindowCard({
    super.key,
    required this.window,
    required this.isLoaded,
    required this.sharedVideoController,
    required this.sharedVideoInitialization,
    required this.isVideoPaused,
    required this.isSelected,
    required this.editMode,
    required this.onOpen,
    required this.onToggleSelected,
    this.onShowInFinder,
    required this.onRemove,
  });

  final AssetWindowState window;
  final bool isLoaded;
  final VideoPlayerController? sharedVideoController;
  final Future<void>? sharedVideoInitialization;
  final bool isVideoPaused;
  final bool isSelected;
  final bool editMode;
  final VoidCallback onOpen;
  final VoidCallback onToggleSelected;
  final VoidCallback? onShowInFinder;
  final VoidCallback onRemove;

  @override
  State<ExposeWindowCard> createState() => _ExposeWindowCardState();
}

class _ExposeWindowCardState extends State<ExposeWindowCard> {
  bool _isHovered = false;
  bool _isCommandPressed = false;

  bool _handleHardwareKey(KeyEvent event) {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final nextIsCommandPressed =
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) || pressedKeys.contains(LogicalKeyboardKey.metaRight);
    if (nextIsCommandPressed == _isCommandPressed || !mounted) {
      return false;
    }
    setState(() {
      _isCommandPressed = nextIsCommandPressed;
    });
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    _isCommandPressed =
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) || pressedKeys.contains(LogicalKeyboardKey.metaRight);
  }

  AssetWindowState _windowForPreview(Size previewSize) {
    if (previewSize.width <= 0 || previewSize.height <= 0) {
      return widget.window;
    }
    final widthScale = previewSize.width / math.max(1.0, widget.window.size.width);
    final heightScale = previewSize.height / math.max(1.0, widget.window.size.height);
    final scale = math.min(widthScale, heightScale);
    return widget.window.copyWith(
      size: previewSize,
      zoomBaseWidth: widget.window.zoomBaseWidth == null ? null : widget.window.zoomBaseWidth! * scale,
      zoomBaseHeight: widget.window.zoomBaseHeight == null ? null : widget.window.zoomBaseHeight! * scale,
      contentOffsetDx: widget.window.contentOffset.dx * scale,
      contentOffsetDy: widget.window.contentOffset.dy * scale,
    );
  }

  Widget _buildMediaPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWindow = _windowForPreview(constraints.biggest);
        return IgnorePointer(
          child: SerenityMediaCanvas(
            window: previewWindow,
            isLoaded: widget.isLoaded,
            sharedVideoController: widget.sharedVideoController,
            sharedVideoInitialization: widget.sharedVideoInitialization,
            onTap: () {},
            onZoomChanged: (_) {},
            onIntrinsicSizeResolved: (_) {},
            isVideoPaused: widget.isVideoPaused,
            onTogglePlayback: () {},
            showVideoControls: false,
            onVideoControlInteractionChanged: (_) {},
            onVideoPositionChanged: (_) {},
            onCycleVideoPlaybackSpeed: () {},
            compactMissingPlaceholder: true,
            videoPreviewMode: true,
          ),
        );
      },
    );
  }

  Widget _buildHoverOverlay(BuildContext context) {
    if (!_isCommandPressed || (!_isHovered && !widget.isSelected)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.58), Colors.black.withValues(alpha: 0.08)],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Material(
              color: widget.isSelected ? const Color(0xFF3B82F6) : Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: widget.onToggleSelected,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(
                    widget.isSelected ? Icons.check_rounded : Icons.circle_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: widget.onRemove,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: widget.onShowInFinder,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            widget.window.asset.filename,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isLoaded)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: SerenityTheme.shadow, blurRadius: 18, offset: Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(fit: StackFit.expand, children: [_buildMediaPreview(), _buildHoverOverlay(context)]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    super.dispose();
  }
}

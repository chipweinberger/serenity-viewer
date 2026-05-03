part of '../../main.dart';

class SerenityMediaCanvas extends StatefulWidget {
  const SerenityMediaCanvas({
    super.key,
    required this.window,
    required this.isLoaded,
    required this.sharedVideoController,
    required this.sharedVideoInitialization,
    required this.onTap,
    required this.onZoomChanged,
    required this.onIntrinsicSizeResolved,
    required this.isVideoPaused,
    required this.onTogglePlayback,
    required this.showVideoControls,
    required this.onVideoControlInteractionChanged,
    required this.onVideoPositionChanged,
    required this.onCycleVideoPlaybackSpeed,
    this.allowDirectContentGestures = false,
    this.compactMissingPlaceholder = false,
    this.videoPreviewMode = false,
  });

  final AssetWindowState window;
  final bool isLoaded;
  final VideoPlayerController? sharedVideoController;
  final Future<void>? sharedVideoInitialization;
  final VoidCallback onTap;
  final ValueChanged<WindowZoomUpdate> onZoomChanged;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final bool isVideoPaused;
  final VoidCallback onTogglePlayback;
  final bool showVideoControls;
  final ValueChanged<bool> onVideoControlInteractionChanged;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;
  final bool allowDirectContentGestures;
  final bool compactMissingPlaceholder;
  final bool videoPreviewMode;

  @override
  State<SerenityMediaCanvas> createState() => _SerenityMediaCanvasState();
}

class _SerenityMediaCanvasState extends State<SerenityMediaCanvas> {
  static const double _maxZoom = 30.0;
  double _gestureStartZoom = 1;
  Offset _gestureStartContentOffset = Offset.zero;
  Size _gestureStartFitSize = Size.zero;
  Offset _gestureAccumulatedPan = Offset.zero;

  Size _fitSizeForViewport(Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return Size.zero;
    }

    final aspectRatio =
        widget.window.asset.type == AssetType.video &&
            (widget.window.asset.intrinsicWidth == null || widget.window.asset.intrinsicHeight == null)
        ? (viewportSize.width / viewportSize.height)
        : widget.window.asset.aspectRatio;
    return _fitSizeForViewportToAspect(viewportSize, aspectRatio);
  }

  @override
  void didUpdateWidget(covariant SerenityMediaCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.window.asset.id != widget.window.asset.id) {
      _gestureStartZoom = 1;
      _gestureStartContentOffset = Offset.zero;
      _gestureStartFitSize = Size.zero;
      _gestureAccumulatedPan = Offset.zero;
    }
  }

  bool _fileExists(String? path) {
    if (path == null || path.isEmpty) {
      return false;
    }
    return File(path).existsSync();
  }

  Widget _buildMissingPlaceholder(BuildContext context) {
    return _SerenityMissingMediaPlaceholder(
      filename: widget.window.asset.filename,
      windowSize: widget.window.size,
      compact: widget.compactMissingPlaceholder,
    );
  }

  Widget _buildUnloadedPlaceholder() {
    return _SerenityUnloadedMediaPlaceholder(asset: widget.window.asset, windowSize: widget.window.size);
  }

  Offset _offsetForFocalZoom({
    required Size viewportSize,
    required Offset focalPoint,
    required double startZoom,
    required double nextZoom,
    required Offset startOffset,
  }) {
    final center = viewportSize.center(Offset.zero);
    final vector = focalPoint - center - startOffset;
    final ratio = nextZoom / startZoom;
    return focalPoint - center - (vector * ratio);
  }

  bool get _isCommandPressed {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    return pressedKeys.contains(LogicalKeyboardKey.metaLeft) || pressedKeys.contains(LogicalKeyboardKey.metaRight);
  }

  bool get _shouldHandleContentGesture {
    return widget.allowDirectContentGestures || _isCommandPressed;
  }

  void _applyZoomFromPoint({
    required Size viewportSize,
    required Offset focalPoint,
    required double nextZoom,
    Offset additionalPan = Offset.zero,
  }) {
    final fitSize = _fitSizeForViewport(viewportSize);
    final clampedZoom = nextZoom.clamp(1.0, _maxZoom);
    final snappedZoom = (clampedZoom - 1).abs() < 0.02 ? 1.0 : clampedZoom;
    widget.onZoomChanged(
      WindowZoomUpdate(
        zoom: snappedZoom,
        zoomBaseSize: snappedZoom > 1.0 ? (widget.window.zoomBaseSize ?? fitSize) : null,
        contentOffset: snappedZoom > 1.0
            ? _offsetForFocalZoom(
                    viewportSize: viewportSize,
                    focalPoint: focalPoint,
                    startZoom: widget.window.zoom,
                    nextZoom: snappedZoom,
                    startOffset: widget.window.contentOffset,
                  ) +
                  additionalPan
            : Offset.zero,
        clearZoomBase: snappedZoom <= 1.0,
        clearContentOffset: snappedZoom <= 1.0,
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_shouldHandleContentGesture) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final nextZoom = widget.window.zoom * math.exp((-event.scrollDelta.dy) / 140);
    _applyZoomFromPoint(viewportSize: size, focalPoint: event.localPosition, nextZoom: nextZoom);
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    if (!_shouldHandleContentGesture) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    _gestureStartFitSize = _fitSizeForViewport(renderBox?.size ?? Size.zero);
    _gestureStartZoom = widget.window.zoom;
    _gestureStartContentOffset = widget.window.contentOffset;
    _gestureAccumulatedPan = Offset.zero;
  }

  void _handlePointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (!_shouldHandleContentGesture) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final viewportSize = renderBox?.size ?? Size.zero;
    _gestureAccumulatedPan += event.panDelta;

    final nextZoom = (_gestureStartZoom * math.pow(event.scale, 1.45)).clamp(1.0, _maxZoom);
    final snappedZoom = (nextZoom - 1).abs() < 0.02 ? 1.0 : nextZoom;
    final acceleratedPan = _gestureAccumulatedPan * 1.45;
    final nextOffset = snappedZoom > 1.0
        ? _offsetForFocalZoom(
                viewportSize: viewportSize,
                focalPoint: event.localPosition,
                startZoom: _gestureStartZoom,
                nextZoom: snappedZoom,
                startOffset: _gestureStartContentOffset,
              ) +
              acceleratedPan
        : Offset.zero;

    widget.onZoomChanged(
      WindowZoomUpdate(
        zoom: snappedZoom,
        zoomBaseSize: snappedZoom > 1.0 ? (widget.window.zoomBaseSize ?? _gestureStartFitSize) : null,
        contentOffset: nextOffset,
        clearZoomBase: snappedZoom <= 1.0,
        clearContentOffset: snappedZoom <= 1.0,
      ),
    );
  }

  void _handlePointerPanZoomEnd(PointerPanZoomEndEvent event) {
    _gestureAccumulatedPan = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final filePath = widget.window.asset.filePath;
    final hasLinkedFile = filePath != null && filePath.isNotEmpty;
    final exists = _fileExists(filePath);

    final media = switch ((widget.isLoaded, hasLinkedFile, exists, widget.window.asset.type)) {
      (false, _, _, _) => _buildUnloadedPlaceholder(),
      (true, false, _, _) => SerenityZoomBox(
        zoom: widget.window.zoom,
        aspectRatio: widget.window.asset.type == AssetType.video ? (16 / 9) : (4 / 3),
        zoomBaseSize: widget.window.zoomBaseSize,
        contentOffset: widget.window.contentOffset,
        child: _SerenityDemoArt(asset: widget.window.asset),
      ),
      (true, true, false, _) => _buildMissingPlaceholder(context),
      (true, true, true, AssetType.image) => SerenityImageSurface(
        path: filePath!,
        zoom: widget.window.zoom,
        zoomBaseSize: widget.window.zoomBaseSize,
        contentOffset: widget.window.contentOffset,
        intrinsicWidth: widget.window.asset.intrinsicWidth,
        intrinsicHeight: widget.window.asset.intrinsicHeight,
        errorBuilder: (context) => _buildMissingPlaceholder(context),
      ),
      (true, true, true, AssetType.video) => SerenityVideoSurface(
        controller: widget.sharedVideoController!,
        initialization: widget.sharedVideoInitialization!,
        path: filePath!,
        zoom: widget.window.zoom,
        zoomBaseSize: widget.window.zoomBaseSize,
        contentOffset: widget.window.contentOffset,
        onIntrinsicSizeResolved: widget.onIntrinsicSizeResolved,
        isPaused: widget.isVideoPaused,
        onTogglePlayback: widget.onTogglePlayback,
        positionMs: widget.window.videoPositionMs,
        playbackSpeed: widget.window.videoPlaybackSpeed,
        onPositionChanged: widget.onVideoPositionChanged,
        onCyclePlaybackSpeed: widget.onCycleVideoPlaybackSpeed,
        showControls: widget.showVideoControls,
        onControlInteractionChanged: widget.onVideoControlInteractionChanged,
        previewMode: widget.videoPreviewMode,
      ),
    };
    final assetColor = widget.window.asset.color;
    final assetColorLight = HSLColor.fromColor(assetColor).withLightness(0.78).toColor();
    final assetColorDeep = HSLColor.fromColor(assetColor).withLightness(0.54).toColor();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: _handlePointerSignal,
        onPointerPanZoomStart: _handlePointerPanZoomStart,
        onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
        onPointerPanZoomEnd: _handlePointerPanZoomEnd,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [assetColorLight, assetColor, assetColorDeep],
            ),
          ),
          child: Stack(children: [Positioned.fill(child: media)]),
        ),
      ),
    );
  }
}

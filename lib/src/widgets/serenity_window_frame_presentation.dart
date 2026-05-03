// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_window_frame.dart';

extension on _SerenityWindowFrameState {
  bool get _isOptionGestureTargetActive {
    return _isOptionPressed && !_isCommandPressed && (widget.isOptionGestureTarget || _claimedOptionGestureTarget);
  }

  bool get _shouldShowCommandOverlay {
    return widget.isPinnedHover || (_isCommandPressed && (_isHovered || _isResizing || widget.isSelected));
  }

  bool get _showExpandedVideoControls => _shouldShowCommandOverlay;

  bool get _showHoverFrame => _shouldShowCommandOverlay;

  WindowResizeHandle? get _hoveredResizeHandle {
    return _hoverPosition == null ? null : _resizeHandleForPosition(_hoverPosition!);
  }

  WindowResizeHandle? get _displayedResizeHandle {
    return _activeResizeHandle ?? _hoveredResizeHandle;
  }

  MouseCursor get _pointerCursor {
    return Platform.isMacOS ? MouseCursor.defer : _cursorForHandle(_displayedResizeHandle);
  }

  void _handleContentTap() {
    if (widget.isPinnedHover) {
      widget.onPinnedHoverDismissed();
      _SerenityWindowFrameState._lastTappedWindowId = null;
      _SerenityWindowFrameState._lastContentTapAt = null;
      return;
    }

    final now = DateTime.now();
    final isDoubleClick =
        _SerenityWindowFrameState._lastTappedWindowId == widget.window.asset.id &&
        _SerenityWindowFrameState._lastContentTapAt != null &&
        now.difference(_SerenityWindowFrameState._lastContentTapAt!) <= _SerenityWindowFrameState._doubleClickThreshold;
    widget.onTap();
    if (isDoubleClick) {
      _SerenityWindowFrameState._lastTappedWindowId = null;
      _SerenityWindowFrameState._lastContentTapAt = null;
      widget.onPinnedHoverRequested();
      return;
    }

    _SerenityWindowFrameState._lastTappedWindowId = widget.window.asset.id;
    _SerenityWindowFrameState._lastContentTapAt = now;
  }

  Widget _buildContent({required bool shrinkContent, required double inset}) {
    return SerenityWindowFrameContent(
      window: widget.window,
      isLoaded: widget.isLoaded,
      sharedVideoController: widget.sharedVideoController,
      sharedVideoInitialization: widget.sharedVideoInitialization,
      isPinnedHover: widget.isPinnedHover,
      showExpandedVideoControls: _showExpandedVideoControls,
      workspaceZoom: widget.workspaceZoom,
      shrinkContent: shrinkContent,
      inset: inset,
      onTap: _handleContentTap,
      onZoomChanged: widget.onZoomChanged,
      onIntrinsicSizeResolved: widget.onIntrinsicSizeResolved,
      isVideoPaused: widget.isVideoPaused,
      onTogglePlayback: widget.onTogglePlayback,
      onVideoControlInteractionChanged: (isInteracting) {
        if (_isInteractingWithVideoControls == isInteracting) {
          return;
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _isInteractingWithVideoControls = isInteracting;
        });
      },
      onVideoPositionChanged: widget.onVideoPositionChanged,
      onCycleVideoPlaybackSpeed: widget.onCycleVideoPlaybackSpeed,
    );
  }

  Widget _buildOverlay() {
    if (!_shouldShowCommandOverlay) {
      return const SizedBox.shrink();
    }

    return SerenityWindowOverlay(
      workspaceZoom: widget.workspaceZoom,
      filename: widget.window.asset.filename,
      isSelected: widget.isSelected,
      onToggleSelected: widget.onToggleSelected,
      onShowInFinder: widget.onShowInFinder,
      onClose: widget.onClose,
      onFitToContent: widget.onFitToContent,
      onRestorePreviousZOrder: widget.onRestorePreviousZOrder,
    );
  }

  Widget _buildFramedWindow() {
    const hoverInset = 3.0;

    return SerenityWindowFrameChrome(
      flashValue: _flashAnimation.value,
      isFocused: widget.isFocused,
      showHoverFrame: _showHoverFrame,
      assetColor: widget.window.asset.color,
      child: Stack(
        children: [
          _buildContent(shrinkContent: _showHoverFrame, inset: hoverInset),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnimatedFrame() {
    return AnimatedBuilder(animation: _flashAnimation, builder: (context, child) => _buildFramedWindow());
  }
}

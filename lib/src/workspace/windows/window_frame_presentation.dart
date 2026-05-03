// ignore_for_file: invalid_use_of_protected_member

part of 'window_frame.dart';

extension on _SerenityWindowFrameState {
  bool get _isOptionGestureTargetActive {
    return _isOptionPressed &&
        !_isCommandPressed &&
        (widget.viewModel.isOptionGestureTarget || _claimedOptionGestureTarget);
  }

  bool get _shouldShowCommandOverlay {
    return widget.viewModel.isPinnedHover ||
        (_isCommandPressed && (_isHovered || _isResizing || widget.viewModel.isSelected));
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
    if (widget.viewModel.isPinnedHover) {
      widget.onPinnedHoverDismissed();
      _SerenityWindowFrameState._lastTappedWindowId = null;
      _SerenityWindowFrameState._lastContentTapAt = null;
      return;
    }

    final now = DateTime.now();
    final isDoubleClick =
        _SerenityWindowFrameState._lastTappedWindowId == widget.viewModel.window.asset.id &&
        _SerenityWindowFrameState._lastContentTapAt != null &&
        now.difference(_SerenityWindowFrameState._lastContentTapAt!) <= _SerenityWindowFrameState._doubleClickThreshold;
    widget.onTap();
    if (isDoubleClick) {
      _SerenityWindowFrameState._lastTappedWindowId = null;
      _SerenityWindowFrameState._lastContentTapAt = null;
      widget.onPinnedHoverRequested();
      return;
    }

    _SerenityWindowFrameState._lastTappedWindowId = widget.viewModel.window.asset.id;
    _SerenityWindowFrameState._lastContentTapAt = now;
  }

  Widget _buildContent({required bool shrinkContent, required double inset}) {
    return SerenityWindowFrameContent(
      viewModel: widget.viewModel,
      showExpandedVideoControls: _showExpandedVideoControls,
      shrinkContent: shrinkContent,
      inset: inset,
      onTap: _handleContentTap,
      onZoomChanged: widget.onZoomChanged,
      onIntrinsicSizeResolved: widget.onIntrinsicSizeResolved,
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
      workspaceZoom: widget.viewModel.workspaceZoom,
      filename: widget.viewModel.window.asset.filename,
      isSelected: widget.viewModel.isSelected,
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
      isFocused: widget.viewModel.isFocused,
      showHoverFrame: _showHoverFrame,
      assetColor: widget.viewModel.window.asset.color,
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

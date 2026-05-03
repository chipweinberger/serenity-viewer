// ignore_for_file: invalid_use_of_protected_member

part of 'asset_window.dart';

extension on _AssetWindowState {
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

  AssetWindowResizeHandle? get _hoveredResizeHandle {
    return _hoverPosition == null ? null : _resizeHandleForPosition(_hoverPosition!);
  }

  AssetWindowResizeHandle? get _displayedResizeHandle {
    return _activeResizeHandle ?? _hoveredResizeHandle;
  }

  MouseCursor get _pointerCursor {
    return Platform.isMacOS ? MouseCursor.defer : _cursorForHandle(_displayedResizeHandle);
  }

  void _handleContentTap() {
    if (widget.viewModel.isPinnedHover) {
      widget.onPinnedHoverDismissed();
      _AssetWindowState._lastTappedWindowId = null;
      _AssetWindowState._lastContentTapAt = null;
      return;
    }

    final now = DateTime.now();
    final isDoubleClick =
        _AssetWindowState._lastTappedWindowId == widget.viewModel.window.asset.id &&
        _AssetWindowState._lastContentTapAt != null &&
        now.difference(_AssetWindowState._lastContentTapAt!) <= _AssetWindowState._doubleClickThreshold;
    widget.onTap();
    if (isDoubleClick) {
      _AssetWindowState._lastTappedWindowId = null;
      _AssetWindowState._lastContentTapAt = null;
      widget.onPinnedHoverRequested();
      return;
    }

    _AssetWindowState._lastTappedWindowId = widget.viewModel.window.asset.id;
    _AssetWindowState._lastContentTapAt = now;
  }

  Widget _buildContent({required bool shrinkContent, required double inset}) {
    return AssetWindowContent(
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

    return AssetWindowOverlay(
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

    return AssetWindowChrome(
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

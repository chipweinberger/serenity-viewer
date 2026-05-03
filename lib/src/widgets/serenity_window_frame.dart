import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/core/serenity_core.dart';
import 'package:serenity_viewer/src/core/serenity_keyboard_modifiers.dart';
import 'package:serenity_viewer/src/models/asset_window_state.dart';
import 'package:serenity_viewer/src/models/window_zoom_update.dart';
import 'package:serenity_viewer/src/widgets/serenity_window_frame_chrome.dart';
import 'package:serenity_viewer/src/widgets/serenity_window_frame_content.dart';
import 'package:serenity_viewer/src/widgets/serenity_window_overlay.dart';
import 'package:serenity_viewer/src/widgets/window_resize_helpers.dart';

class SerenityWindowFrame extends StatefulWidget {
  const SerenityWindowFrame({
    super.key,
    required this.window,
    required this.isLoaded,
    required this.sharedVideoController,
    required this.sharedVideoInitialization,
    required this.isFocused,
    required this.isSelected,
    required this.isEditing,
    required this.isPinnedHover,
    required this.workspaceZoom,
    required this.flashNonce,
    required this.onTap,
    required this.onPinnedHoverRequested,
    required this.onPinnedHoverDismissed,
    required this.onToggleSelected,
    required this.onPanUpdate,
    required this.onTrackpadWindowScale,
    required this.onResizeUpdate,
    required this.onZoomChanged,
    required this.onIntrinsicSizeResolved,
    required this.isVideoPaused,
    required this.onVideoPositionChanged,
    required this.onCycleVideoPlaybackSpeed,
    required this.onTogglePlayback,
    this.onFitToContent,
    this.onShowInFinder,
    this.onRestorePreviousZOrder,
    required this.onClose,
    required this.isOptionGestureTarget,
    required this.onOptionGestureWindowRequested,
    required this.onOptionGestureReleased,
  });

  final AssetWindowState window;
  final bool isLoaded;
  final VideoPlayerController? sharedVideoController;
  final Future<void>? sharedVideoInitialization;
  final bool isFocused;
  final bool isSelected;
  final bool isEditing;
  final bool isPinnedHover;
  final double workspaceZoom;
  final int flashNonce;
  final VoidCallback onTap;
  final VoidCallback onPinnedHoverRequested;
  final VoidCallback onPinnedHoverDismissed;
  final VoidCallback onToggleSelected;
  final ValueChanged<Offset> onPanUpdate;
  final void Function(double scaleDelta, Offset localFocalPoint) onTrackpadWindowScale;
  final void Function(WindowResizeHandle handle, Offset delta) onResizeUpdate;
  final ValueChanged<WindowZoomUpdate> onZoomChanged;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final bool isVideoPaused;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;
  final VoidCallback onTogglePlayback;
  final VoidCallback? onFitToContent;
  final VoidCallback? onShowInFinder;
  final VoidCallback? onRestorePreviousZOrder;
  final VoidCallback onClose;
  final bool isOptionGestureTarget;
  final VoidCallback onOptionGestureWindowRequested;
  final VoidCallback onOptionGestureReleased;

  @override
  State<SerenityWindowFrame> createState() => _SerenityWindowFrameState();
}

class _SerenityWindowFrameState extends State<SerenityWindowFrame> with SingleTickerProviderStateMixin {
  static bool _anyWindowResizing = false;
  static const Duration _doubleClickThreshold = Duration(milliseconds: 275);
  static String? _lastTappedWindowId;
  static DateTime? _lastContentTapAt;

  bool _isHovered = false;
  bool _isResizing = false;
  bool _isInteractingWithVideoControls = false;
  bool _isCommandPressed = false;
  bool _isOptionPressed = false;
  bool _isTrackpadWindowGestureActive = false;
  bool _isDraggingWindow = false;
  bool _claimedOptionGestureTarget = false;
  double _lastTrackpadScale = 1.0;
  Offset? _hoverPosition;
  WindowResizeHandle? _activeResizeHandle;
  String? _lastNativeCursorKind;
  late final AnimationController _flashController;
  late final Animation<double> _flashAnimation;

  bool _handleHardwareKey(KeyEvent event) {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final nextIsCommandPressed = isCommandPressed(pressedKeys);
    final nextIsOptionPressed = isOptionPressed(pressedKeys);
    if ((nextIsCommandPressed == _isCommandPressed && nextIsOptionPressed == _isOptionPressed) || !mounted) {
      return false;
    }
    final wasOptionPressed = _isOptionPressed;
    setState(() {
      _isCommandPressed = nextIsCommandPressed;
      _isOptionPressed = nextIsOptionPressed;
      if (!nextIsOptionPressed) {
        _claimedOptionGestureTarget = false;
      }
    });
    if (nextIsCommandPressed && widget.isPinnedHover) {
      widget.onPinnedHoverDismissed();
    }
    if (!wasOptionPressed && nextIsOptionPressed && _isHovered) {
      _claimedOptionGestureTarget = true;
      widget.onOptionGestureWindowRequested();
    } else if (wasOptionPressed && !nextIsOptionPressed) {
      _isTrackpadWindowGestureActive = false;
      _lastTrackpadScale = 1.0;
      widget.onOptionGestureReleased();
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 1),
    ]).animate(_flashController);
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    _isCommandPressed = isCommandPressed(pressedKeys);
    _isOptionPressed = isOptionPressed(pressedKeys);
    if (widget.flashNonce != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_flashController.forward(from: 0));
      });
    }
  }

  @override
  void didUpdateWidget(covariant SerenityWindowFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashNonce != 0 && widget.flashNonce != oldWidget.flashNonce) {
      unawaited(_flashController.forward(from: 0));
    }
  }

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
      _lastTappedWindowId = null;
      _lastContentTapAt = null;
      return;
    }

    final now = DateTime.now();
    final isDoubleClick =
        _lastTappedWindowId == widget.window.asset.id &&
        _lastContentTapAt != null &&
        now.difference(_lastContentTapAt!) <= _doubleClickThreshold;
    widget.onTap();
    if (isDoubleClick) {
      _lastTappedWindowId = null;
      _lastContentTapAt = null;
      widget.onPinnedHoverRequested();
      return;
    }

    _lastTappedWindowId = widget.window.asset.id;
    _lastContentTapAt = now;
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

  WindowResizeHandle? _resizeHandleForPosition(Offset localPosition) {
    return windowResizeHandleForPosition(windowSize: widget.window.size, localPosition: localPosition);
  }

  MouseCursor _cursorForHandle(WindowResizeHandle? handle) {
    return mouseCursorForResizeHandle(handle);
  }

  String _nativeCursorKindForHandle(WindowResizeHandle? handle) {
    return nativeCursorKindForResizeHandle(handle);
  }

  void _syncNativeCursor(WindowResizeHandle? handle) {
    if (!Platform.isMacOS) {
      return;
    }

    final nextKind = _nativeCursorKindForHandle(handle);
    if (_lastNativeCursorKind == nextKind) {
      return;
    }

    _lastNativeCursorKind = nextKind;
    unawaited(cursorChannel.invokeMethod<void>('setCursor', {'kind': nextKind}).catchError((_) {}));
  }

  void _updateHoverPosition(Offset localPosition) {
    if (_hoverPosition == localPosition) {
      return;
    }
    _syncNativeCursor(_activeResizeHandle ?? _resizeHandleForPosition(localPosition));
    if (!mounted) {
      return;
    }
    setState(() {
      _hoverPosition = localPosition;
    });
  }

  void _clearResizeState({bool preserveHover = false}) {
    if (!_isResizing && _activeResizeHandle == null && (preserveHover || _hoverPosition == null)) {
      return;
    }
    if (!mounted) {
      _anyWindowResizing = false;
      return;
    }
    setState(() {
      _isResizing = false;
      _activeResizeHandle = null;
      if (!preserveHover) {
        _hoverPosition = null;
      }
    });
    _anyWindowResizing = false;
    _isDraggingWindow = false;
    _syncNativeCursor(preserveHover && _hoverPosition != null ? _resizeHandleForPosition(_hoverPosition!) : null);
  }

  void _clearHoverState() {
    _syncNativeCursor(null);
    if (!mounted) {
      return;
    }
    setState(() {
      _isHovered = false;
      _hoverPosition = null;
    });
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    if (_anyWindowResizing && !_isResizing) {
      return;
    }
    _syncNativeCursor(_resizeHandleForPosition(event.localPosition));
    if (!mounted) {
      return;
    }
    setState(() {
      _isHovered = true;
      _hoverPosition = event.localPosition;
    });
  }

  void _handleMouseHover(PointerHoverEvent event) {
    if (_anyWindowResizing && !_isResizing) {
      if (_isHovered || _hoverPosition != null) {
        _clearHoverState();
      }
      return;
    }
    _updateHoverPosition(event.localPosition);
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (_isResizing) {
      return;
    }
    _clearHoverState();
  }

  void _beginResize(PointerDownEvent event, WindowResizeHandle handle) {
    _syncNativeCursor(handle);
    _anyWindowResizing = true;
    if (!mounted) {
      return;
    }
    setState(() {
      _isHovered = true;
      _isResizing = true;
      _activeResizeHandle = handle;
      _hoverPosition = event.localPosition;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != ui.PointerDeviceKind.mouse || event.buttons != kPrimaryMouseButton) {
      return;
    }

    final resizeHandle = _resizeHandleForPosition(event.localPosition);
    if (resizeHandle != null) {
      _beginResize(event, resizeHandle);
    }
  }

  void _dragWindow(Offset delta) {
    if (_isInteractingWithVideoControls) {
      return;
    }

    if (!_isDraggingWindow) {
      _isDraggingWindow = true;
      widget.onTap();
    }
    widget.onPanUpdate(delta);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.kind != ui.PointerDeviceKind.mouse) {
      return;
    }

    _updateHoverPosition(event.localPosition);

    if (event.buttons != kPrimaryMouseButton) {
      return;
    }

    final resizeHandle = _activeResizeHandle;
    if (resizeHandle != null) {
      widget.onResizeUpdate(resizeHandle, event.delta);
      return;
    }

    _dragWindow(event.delta);
  }

  void _handlePanZoomStart(PointerPanZoomStartEvent event) {
    _isTrackpadWindowGestureActive = _isOptionGestureTargetActive;
    _lastTrackpadScale = 1.0;
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (!_isTrackpadWindowGestureActive) {
      return;
    }
    final scaleDelta = event.scale / _lastTrackpadScale;
    _lastTrackpadScale = event.scale;
    widget.onTrackpadWindowScale(scaleDelta, event.localPosition);
  }

  void _handlePanZoomEnd(PointerPanZoomEndEvent event) {
    _isTrackpadWindowGestureActive = false;
    _lastTrackpadScale = 1.0;
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

  @override
  void dispose() {
    if (_isResizing) {
      _anyWindowResizing = false;
    }
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _syncNativeCursor(null);
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _pointerCursor,
      onEnter: _handleMouseEnter,
      onHover: _handleMouseHover,
      onExit: _handleMouseExit,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: (_) => _clearResizeState(preserveHover: true),
        onPointerCancel: (_) => _clearResizeState(preserveHover: false),
        onPointerPanZoomStart: _handlePanZoomStart,
        onPointerPanZoomUpdate: _handlePanZoomUpdate,
        onPointerPanZoomEnd: _handlePanZoomEnd,
        child: _buildAnimatedFrame(),
      ),
    );
  }
}

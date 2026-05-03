import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/core/serenity_core.dart';
import 'package:serenity_viewer/src/models/asset_window_state.dart';
import 'package:serenity_viewer/src/models/window_zoom_update.dart';
import 'package:serenity_viewer/src/widgets/serenity_media_canvas.dart';
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
    final nextIsCommandPressed =
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) || pressedKeys.contains(LogicalKeyboardKey.metaRight);
    final nextIsOptionPressed =
        pressedKeys.contains(LogicalKeyboardKey.altLeft) || pressedKeys.contains(LogicalKeyboardKey.altRight);
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
    _isCommandPressed =
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) || pressedKeys.contains(LogicalKeyboardKey.metaRight);
    _isOptionPressed =
        pressedKeys.contains(LogicalKeyboardKey.altLeft) || pressedKeys.contains(LogicalKeyboardKey.altRight);
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

  AssetWindowState _windowForHoverPreview({required bool shrinkContent, required double inset}) {
    final scale = _hoverPreviewScale(shrinkContent: shrinkContent, inset: inset);
    if (scale == 1.0) {
      return widget.window;
    }

    return widget.window.copyWith(
      zoomBaseWidth: widget.window.zoomBaseWidth == null ? null : widget.window.zoomBaseWidth! * scale,
      zoomBaseHeight: widget.window.zoomBaseHeight == null ? null : widget.window.zoomBaseHeight! * scale,
      contentOffsetDx: widget.window.contentOffset.dx * scale,
      contentOffsetDy: widget.window.contentOffset.dy * scale,
    );
  }

  double _hoverPreviewScale({required bool shrinkContent, required double inset}) {
    if (!shrinkContent || inset <= 0 || widget.window.size.width <= 0 || widget.window.size.height <= 0) {
      return 1.0;
    }

    final innerWidth = math.max(1.0, widget.window.size.width - (inset * 2));
    final innerHeight = math.max(1.0, widget.window.size.height - (inset * 2));
    return math.min(innerWidth / widget.window.size.width, innerHeight / widget.window.size.height);
  }

  WindowZoomUpdate _zoomUpdateForWindowState(
    WindowZoomUpdate update, {
    required bool shrinkContent,
    required double inset,
  }) {
    final scale = _hoverPreviewScale(shrinkContent: shrinkContent, inset: inset);
    if (scale == 1.0) {
      return update;
    }

    return WindowZoomUpdate(
      zoom: update.zoom,
      zoomBaseSize: update.zoomBaseSize == null
          ? null
          : Size(update.zoomBaseSize!.width / scale, update.zoomBaseSize!.height / scale),
      contentOffset: update.contentOffset == null
          ? null
          : Offset(update.contentOffset!.dx / scale, update.contentOffset!.dy / scale),
      clearZoomBase: update.clearZoomBase,
      clearContentOffset: update.clearContentOffset,
    );
  }

  Widget _buildContent({required bool shrinkContent, required double inset}) {
    final previewWindow = _windowForHoverPreview(shrinkContent: shrinkContent, inset: inset);
    final showExpandedVideoControls =
        widget.isPinnedHover || (_isCommandPressed && (_isHovered || _isResizing || widget.isSelected));

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SerenityMediaCanvas(
          key: ValueKey(widget.window.asset.id),
          window: previewWindow,
          isLoaded: widget.isLoaded,
          sharedVideoController: widget.sharedVideoController,
          sharedVideoInitialization: widget.sharedVideoInitialization,
          onTap: _handleContentTap,
          onZoomChanged: (update) {
            widget.onZoomChanged(_zoomUpdateForWindowState(update, shrinkContent: shrinkContent, inset: inset));
          },
          onIntrinsicSizeResolved: widget.onIntrinsicSizeResolved,
          isVideoPaused: widget.isVideoPaused,
          onTogglePlayback: widget.onTogglePlayback,
          showVideoControls: true,
          showExpandedVideoControls: showExpandedVideoControls,
          workspaceZoom: widget.workspaceZoom,
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
          allowDirectContentGestures: widget.isPinnedHover,
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    final shouldShowCommandOverlay =
        widget.isPinnedHover || (_isCommandPressed && (_isHovered || _isResizing || widget.isSelected));
    if (!shouldShowCommandOverlay) {
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
    final hoveredResizeHandle = _hoverPosition == null ? null : _resizeHandleForPosition(_hoverPosition!);
    final activeResizeHandle = _activeResizeHandle ?? hoveredResizeHandle;
    final pointerCursor = Platform.isMacOS ? MouseCursor.defer : _cursorForHandle(activeResizeHandle);

    return MouseRegion(
      cursor: pointerCursor,
      onEnter: (event) {
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
      },
      onHover: (event) {
        if (_anyWindowResizing && !_isResizing) {
          if (_isHovered || _hoverPosition != null) {
            _syncNativeCursor(null);
            if (!mounted) {
              return;
            }
            setState(() {
              _isHovered = false;
              _hoverPosition = null;
            });
          }
          return;
        }
        _updateHoverPosition(event.localPosition);
      },
      onExit: (_) {
        if (!_isResizing) {
          _syncNativeCursor(null);
          if (!mounted) {
            return;
          }
          setState(() {
            _isHovered = false;
            _hoverPosition = null;
          });
        }
      },
      child: Listener(
        onPointerDown: (event) {
          if (event.kind == ui.PointerDeviceKind.mouse && event.buttons == kPrimaryMouseButton) {
            final resizeHandle = _resizeHandleForPosition(event.localPosition);
            if (resizeHandle != null) {
              _syncNativeCursor(resizeHandle);
              _anyWindowResizing = true;
              if (!mounted) {
                return;
              }
              setState(() {
                _isHovered = true;
                _isResizing = true;
                _activeResizeHandle = resizeHandle;
                _hoverPosition = event.localPosition;
              });
            }
          }
        },
        onPointerMove: (event) {
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

          if (_isInteractingWithVideoControls) {
            return;
          }

          if (!_isDraggingWindow) {
            _isDraggingWindow = true;
            widget.onTap();
          }
          widget.onPanUpdate(event.delta);
        },
        onPointerUp: (_) => _clearResizeState(preserveHover: true),
        onPointerCancel: (_) => _clearResizeState(preserveHover: false),
        onPointerPanZoomStart: (_) {
          _isTrackpadWindowGestureActive = _isOptionGestureTargetActive;
          _lastTrackpadScale = 1.0;
        },
        onPointerPanZoomUpdate: (event) {
          if (!_isTrackpadWindowGestureActive) {
            return;
          }
          final scaleDelta = event.scale / _lastTrackpadScale;
          _lastTrackpadScale = event.scale;
          widget.onTrackpadWindowScale(scaleDelta, event.localPosition);
        },
        onPointerPanZoomEnd: (_) {
          _isTrackpadWindowGestureActive = false;
          _lastTrackpadScale = 1.0;
        },
        child: AnimatedBuilder(
          animation: _flashAnimation,
          builder: (context, child) {
            final flashValue = _flashAnimation.value;
            final focusShadowAlpha = widget.isFocused ? 0.26 : 0.18;
            final focusBlurRadius = widget.isFocused ? 34.0 : 22.0;
            final flashScale = 1 + (0.035 * flashValue);
            final showHoverFrame =
                widget.isPinnedHover || (_isCommandPressed && (_isHovered || _isResizing || widget.isSelected));
            const hoverInset = 3.0;
            final assetColor = widget.window.asset.color;
            final assetColorLight = HSLColor.fromColor(assetColor).withLightness(0.82).toColor();
            final assetColorDeep = HSLColor.fromColor(assetColor).withLightness(0.46).toColor();

            return Transform.scale(
              scale: flashScale,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: focusShadowAlpha + (0.08 * flashValue)),
                      blurRadius: focusBlurRadius + (12 * flashValue),
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: showHoverFrame
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [assetColorLight, assetColor, assetColorDeep],
                            stops: const [0.0, 0.42, 1.0],
                          )
                        : null,
                  ),
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.all(showHoverFrame ? hoverInset : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(showHoverFrame ? 13 : 16),
                      child: Stack(
                        children: [
                          _buildContent(shrinkContent: showHoverFrame, inset: hoverInset),
                          _buildOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

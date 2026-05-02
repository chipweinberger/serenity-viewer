part of '../../main.dart';

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
    required this.onTap,
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
  final VoidCallback onTap;
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

class _SerenityWindowFrameState extends State<SerenityWindowFrame> {
  static bool _anyWindowResizing = false;

  bool _isHovered = false;
  bool _isResizing = false;
  bool _isInteractingWithVideoControls = false;
  bool _isCommandPressed = false;
  bool _isOptionPressed = false;
  bool _isTrackpadWindowGestureActive = false;
  bool _claimedOptionGestureTarget = false;
  double _lastTrackpadScale = 1.0;
  Offset? _hoverPosition;
  WindowResizeHandle? _activeResizeHandle;
  String? _lastNativeCursorKind;

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
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    _isCommandPressed =
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) || pressedKeys.contains(LogicalKeyboardKey.metaRight);
    _isOptionPressed =
        pressedKeys.contains(LogicalKeyboardKey.altLeft) || pressedKeys.contains(LogicalKeyboardKey.altRight);
  }

  bool get _isOptionGestureTargetActive {
    return _isOptionPressed && !_isCommandPressed && (widget.isOptionGestureTarget || _claimedOptionGestureTarget);
  }

  Widget _buildContent() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SerenityMediaCanvas(
          key: ValueKey(widget.window.asset.id),
          window: widget.window,
          isLoaded: widget.isLoaded,
          sharedVideoController: widget.sharedVideoController,
          sharedVideoInitialization: widget.sharedVideoInitialization,
          onTap: widget.onTap,
          onZoomChanged: widget.onZoomChanged,
          onIntrinsicSizeResolved: widget.onIntrinsicSizeResolved,
          isVideoPaused: widget.isVideoPaused,
          onTogglePlayback: widget.onTogglePlayback,
          showVideoControls: _isCommandPressed && (_isHovered || _isResizing),
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
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    if (!_isCommandPressed || (!_isHovered && !_isResizing && !widget.isSelected)) {
      return const SizedBox.shrink();
    }

    return _SerenityWindowOverlay(
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
    return _windowResizeHandleForPosition(windowSize: widget.window.size, localPosition: localPosition);
  }

  MouseCursor _cursorForHandle(WindowResizeHandle? handle) {
    return _mouseCursorForResizeHandle(handle);
  }

  String _nativeCursorKindForHandle(WindowResizeHandle? handle) {
    return _nativeCursorKindForResizeHandle(handle);
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
    unawaited(_cursorChannel.invokeMethod<void>('setCursor', {'kind': nextKind}).catchError((_) {}));
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
    _syncNativeCursor(preserveHover && _hoverPosition != null ? _resizeHandleForPosition(_hoverPosition!) : null);
  }

  @override
  void dispose() {
    if (_isResizing) {
      _anyWindowResizing = false;
    }
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _syncNativeCursor(null);
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isFocused ? 0.26 : 0.18),
                blurRadius: widget.isFocused ? 34 : 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(children: [_buildContent(), _buildOverlay()]),
        ),
      ),
    );
  }
}

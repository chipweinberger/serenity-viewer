// ignore_for_file: invalid_use_of_protected_member

part of 'window_frame.dart';

extension on _WindowFrameState {
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
    if (nextIsCommandPressed && widget.viewModel.isPinnedHover) {
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

  WindowResizeHandle? _resizeHandleForPosition(Offset localPosition) {
    return windowResizeHandleForPosition(windowSize: widget.viewModel.window.size, localPosition: localPosition);
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
      _WindowFrameState._anyWindowResizing = false;
      return;
    }
    setState(() {
      _isResizing = false;
      _activeResizeHandle = null;
      if (!preserveHover) {
        _hoverPosition = null;
      }
    });
    _WindowFrameState._anyWindowResizing = false;
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
    if (_WindowFrameState._anyWindowResizing && !_isResizing) {
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
    if (_WindowFrameState._anyWindowResizing && !_isResizing) {
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
    _WindowFrameState._anyWindowResizing = true;
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
}

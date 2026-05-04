import 'dart:async';

import 'package:flutter/material.dart';

@immutable
class WindowGestureDragAnchor {
  const WindowGestureDragAnchor({
    required this.windowId,
    required this.globalStartPosition,
    required this.windowStartPosition,
  });

  final String windowId;
  final Offset globalStartPosition;
  final Offset windowStartPosition;
}

class WindowInteractionState extends ChangeNotifier {
  final Map<String, bool> _pausedVideoWindows = {};
  final Map<String, int> _previousWindowZOrders = {};
  final Set<String> _selectedExposeWindowIds = {};

  String? _activeGestureWindowId;
  String? _pinnedHoverWindowId;
  String? _flashedWindowId;
  WindowGestureDragAnchor? _activeGestureDragAnchor;
  int _windowFlashNonce = 0;
  bool _isCommandPressed = false;
  bool _isOptionPressed = false;
  Timer? windowFlashTimer;
  bool _isDisposed = false;

  Map<String, bool> get pausedVideoWindows => _pausedVideoWindows;
  Map<String, int> get previousWindowZOrders => _previousWindowZOrders;
  Set<String> get selectedExposeWindowIds => _selectedExposeWindowIds;

  String? get activeGestureWindowId => _activeGestureWindowId;
  String? get pinnedHoverWindowId => _pinnedHoverWindowId;
  String? get flashedWindowId => _flashedWindowId;
  WindowGestureDragAnchor? get activeGestureDragAnchor => _activeGestureDragAnchor;
  int get windowFlashNonce => _windowFlashNonce;
  bool get isCommandPressed => _isCommandPressed;
  bool get isOptionPressed => _isOptionPressed;

  bool toggleSelectedExposeWindow(String windowId) {
    final changed = _selectedExposeWindowIds.contains(windowId)
        ? _selectedExposeWindowIds.remove(windowId)
        : _selectedExposeWindowIds.add(windowId);
    _notifyIfNeeded(changed);
    return changed;
  }

  bool clearSelectedExposeWindows() {
    if (_selectedExposeWindowIds.isEmpty) {
      return false;
    }
    _selectedExposeWindowIds.clear();
    _notifyIfNeeded(true);
    return true;
  }

  bool removeSelectedExposeWindow(String windowId) {
    final changed = _selectedExposeWindowIds.remove(windowId);
    _notifyIfNeeded(changed);
    return changed;
  }

  bool setActiveGestureWindow(String? windowId) {
    if (_activeGestureWindowId == windowId) {
      return false;
    }
    _activeGestureWindowId = windowId;
    if (_activeGestureDragAnchor?.windowId != windowId) {
      _activeGestureDragAnchor = null;
    }
    _notifyIfNeeded(true);
    return true;
  }

  void setActiveGestureDragAnchor({
    required String windowId,
    required Offset globalStartPosition,
    required Offset windowStartPosition,
  }) {
    _activeGestureDragAnchor = WindowGestureDragAnchor(
      windowId: windowId,
      globalStartPosition: globalStartPosition,
      windowStartPosition: windowStartPosition,
    );
  }

  void clearActiveGestureDragAnchor() {
    _activeGestureDragAnchor = null;
  }

  bool setPinnedHoverWindow(String? windowId) {
    if (_pinnedHoverWindowId == windowId) {
      return false;
    }
    _pinnedHoverWindowId = windowId;
    _notifyIfNeeded(true);
    return true;
  }

  bool setWindowPaused(String windowId, bool isPaused) {
    if (_pausedVideoWindows[windowId] == isPaused) {
      return false;
    }
    _pausedVideoWindows[windowId] = isPaused;
    _notifyIfNeeded(true);
    return true;
  }

  bool removePausedVideoWindow(String windowId) {
    final changed = _pausedVideoWindows.remove(windowId) != null;
    _notifyIfNeeded(changed);
    return changed;
  }

  bool pauseAllVideoWindows(Iterable<String> windowIds) {
    var changed = false;
    for (final windowId in windowIds) {
      if (_pausedVideoWindows[windowId] != true) {
        _pausedVideoWindows[windowId] = true;
        changed = true;
      }
    }
    _notifyIfNeeded(changed);
    return changed;
  }

  bool playAllVideoWindows(Iterable<String> windowIds) {
    var changed = false;
    for (final windowId in windowIds) {
      if (_pausedVideoWindows[windowId] != false) {
        _pausedVideoWindows[windowId] = false;
        changed = true;
      }
    }
    _notifyIfNeeded(changed);
    return changed;
  }

  bool rememberPreviousWindowZOrder(String windowId, int previousZOrder) {
    if (_previousWindowZOrders[windowId] == previousZOrder) {
      return false;
    }
    _previousWindowZOrders[windowId] = previousZOrder;
    _notifyIfNeeded(true);
    return true;
  }

  int? takePreviousWindowZOrder(String windowId) {
    final previousZOrder = _previousWindowZOrders.remove(windowId);
    _notifyIfNeeded(previousZOrder != null);
    return previousZOrder;
  }

  void clearWindowRuntimeState(String windowId) {
    final removedPreviousZOrder = _previousWindowZOrders.remove(windowId) != null;
    final removedPaused = _pausedVideoWindows.remove(windowId) != null;
    _notifyIfNeeded(removedPreviousZOrder || removedPaused);
  }

  void showWindowFlash(String windowId) {
    _flashedWindowId = windowId;
    _windowFlashNonce += 1;
    _notifyIfNeeded(true);
  }

  void clearWindowFlash(String windowId) {
    if (_flashedWindowId != windowId) {
      return;
    }
    _flashedWindowId = null;
    _notifyIfNeeded(true);
  }

  bool setModifierKeys({required bool isCommandPressed, required bool isOptionPressed}) {
    if (_isCommandPressed == isCommandPressed && _isOptionPressed == isOptionPressed) {
      return false;
    }

    _isCommandPressed = isCommandPressed;
    _isOptionPressed = isOptionPressed;
    _notifyIfNeeded(true);
    return true;
  }

  void _notifyIfNeeded(bool changed) {
    if (!changed || _isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    windowFlashTimer?.cancel();
    windowFlashTimer = null;
    super.dispose();
  }
}

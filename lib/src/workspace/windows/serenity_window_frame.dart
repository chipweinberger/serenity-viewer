import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:serenity_viewer/src/foundation/serenity_core.dart';
import 'package:serenity_viewer/src/foundation/serenity_keyboard_modifiers.dart';
import 'package:serenity_viewer/src/workspace/windows/serenity_window_frame_view_model.dart';
import 'package:serenity_viewer/src/workspace/windows/window_zoom_update.dart';
import 'package:serenity_viewer/src/workspace/windows/serenity_window_frame_chrome.dart';
import 'package:serenity_viewer/src/workspace/windows/serenity_window_frame_content.dart';
import 'package:serenity_viewer/src/workspace/windows/serenity_window_overlay.dart';
import 'package:serenity_viewer/src/workspace/windows/window_resize_helpers.dart';

part 'serenity_window_frame_interactions.dart';
part 'serenity_window_frame_presentation.dart';

class SerenityWindowFrame extends StatefulWidget {
  const SerenityWindowFrame({
    super.key,
    required this.viewModel,
    required this.onTap,
    required this.onPinnedHoverRequested,
    required this.onPinnedHoverDismissed,
    required this.onToggleSelected,
    required this.onPanUpdate,
    required this.onTrackpadWindowScale,
    required this.onResizeUpdate,
    required this.onZoomChanged,
    required this.onIntrinsicSizeResolved,
    required this.onVideoPositionChanged,
    required this.onCycleVideoPlaybackSpeed,
    required this.onTogglePlayback,
    this.onFitToContent,
    this.onShowInFinder,
    this.onRestorePreviousZOrder,
    required this.onClose,
    required this.onOptionGestureWindowRequested,
    required this.onOptionGestureReleased,
  });

  final SerenityWindowFrameViewModel viewModel;
  final VoidCallback onTap;
  final VoidCallback onPinnedHoverRequested;
  final VoidCallback onPinnedHoverDismissed;
  final VoidCallback onToggleSelected;
  final ValueChanged<Offset> onPanUpdate;
  final void Function(double scaleDelta, Offset localFocalPoint) onTrackpadWindowScale;
  final void Function(WindowResizeHandle handle, Offset delta) onResizeUpdate;
  final ValueChanged<WindowZoomUpdate> onZoomChanged;
  final ValueChanged<Size> onIntrinsicSizeResolved;
  final ValueChanged<int> onVideoPositionChanged;
  final VoidCallback onCycleVideoPlaybackSpeed;
  final VoidCallback onTogglePlayback;
  final VoidCallback? onFitToContent;
  final VoidCallback? onShowInFinder;
  final VoidCallback? onRestorePreviousZOrder;
  final VoidCallback onClose;
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
    if (widget.viewModel.flashNonce != 0) {
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
    if (widget.viewModel.flashNonce != 0 && widget.viewModel.flashNonce != oldWidget.viewModel.flashNonce) {
      unawaited(_flashController.forward(from: 0));
    }
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

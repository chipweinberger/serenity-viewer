import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/window/content/workspace_window_content.dart';
import 'package:serenity_viewer/src/window/frame/window_chrome.dart';
import 'package:serenity_viewer/src/window/frame/window_overlay.dart';
import 'package:serenity_viewer/src/window/frame/window_resize_helpers.dart';
import 'package:serenity_viewer/src/window/interaction/window_zoom_update.dart';
import 'package:serenity_viewer/src/window/presentation/workspace_window_view_model.dart';

part 'window_pointer_interactions.dart';
part 'window_frame_builder.dart';

class WorkspaceWindow extends StatefulWidget {
  const WorkspaceWindow({
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

  final WorkspaceWindowViewModel viewModel;
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
  State<WorkspaceWindow> createState() => _WindowState();
}

class _WindowState extends State<WorkspaceWindow> with SingleTickerProviderStateMixin {
  static bool _anyWindowResizing = false;
  static const Duration _doubleClickThreshold = Duration(milliseconds: 275);
  static String? _lastTappedWindowId;
  static DateTime? _lastContentTapAt;

  bool _isHovered = false;
  bool _isResizing = false;
  bool _isInteractingWithVideoControls = false;
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
  void didUpdateWidget(covariant WorkspaceWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel.flashNonce != 0 && widget.viewModel.flashNonce != oldWidget.viewModel.flashNonce) {
      unawaited(_flashController.forward(from: 0));
    }
    _syncModifierState(oldWidget);
  }

  @override
  void dispose() {
    if (_isResizing) {
      _anyWindowResizing = false;
    }
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

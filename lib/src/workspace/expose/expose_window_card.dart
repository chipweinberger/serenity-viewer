import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/foundation/keyboard_modifiers.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/environment/workspace_window_state.dart';
import 'package:serenity_viewer/src/media/assets/media_canvas.dart';
import 'package:serenity_viewer/src/media/assets/media_preview_transforms.dart';

class ExposeWindowCard extends StatefulWidget {
  const ExposeWindowCard({
    super.key,
    required this.window,
    required this.isLoaded,
    required this.sharedVideoController,
    required this.sharedVideoInitialization,
    required this.isVideoPaused,
    required this.isSelected,
    required this.editMode,
    required this.onOpen,
    required this.onToggleSelected,
    this.onShowInFinder,
    required this.onRemove,
  });

  final WorkspaceWindowState window;
  final bool isLoaded;
  final VideoPlayerController? sharedVideoController;
  final Future<void>? sharedVideoInitialization;
  final bool isVideoPaused;
  final bool isSelected;
  final bool editMode;
  final VoidCallback onOpen;
  final VoidCallback onToggleSelected;
  final VoidCallback? onShowInFinder;
  final VoidCallback onRemove;

  @override
  State<ExposeWindowCard> createState() => _ExposeWindowCardState();
}

class _ExposeWindowCardState extends State<ExposeWindowCard> {
  static const double _maxCardCornerRadius = 20.0;

  bool _isHovered = false;
  bool _isCommandPressed = false;

  bool _handleHardwareKey(KeyEvent event) {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final nextIsCommandPressed = isCommandPressed(pressedKeys);
    if (nextIsCommandPressed == _isCommandPressed || !mounted) {
      return false;
    }
    setState(() {
      _isCommandPressed = nextIsCommandPressed;
    });
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    _isCommandPressed = isCommandPressed(pressedKeys);
  }

  WorkspaceWindowState _windowForPreview(Size previewSize) {
    final scale = previewWindowScaleForSize(widget.window, previewSize);
    return scalePreviewWindow(widget.window, scale, size: previewSize);
  }

  Widget _buildMediaPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWindow = _windowForPreview(constraints.biggest);
        return IgnorePointer(
          child: MediaCanvas(
            window: previewWindow,
            isLoaded: widget.isLoaded,
            sharedVideoController: widget.sharedVideoController,
            sharedVideoInitialization: widget.sharedVideoInitialization,
            onTap: () {},
            onZoomChanged: (_) {},
            onIntrinsicSizeResolved: (_) {},
            isVideoPaused: widget.isVideoPaused,
            onTogglePlayback: () {},
            showVideoControls: false,
            showExpandedVideoControls: false,
            workspaceZoom: 1,
            onVideoControlInteractionChanged: (_) {},
            onVideoPositionChanged: (_) {},
            onCycleVideoPlaybackSpeed: () {},
            compactMissingPlaceholder: true,
            videoPreviewMode: true,
          ),
        );
      },
    );
  }

  Widget _buildHoverOverlay(BuildContext context) {
    if (!_isCommandPressed || (!_isHovered && !widget.isSelected)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.58), Colors.black.withValues(alpha: 0.08)],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Material(
              color: widget.isSelected ? const Color(0xFF3B82F6) : Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: widget.onToggleSelected,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(
                    widget.isSelected ? Icons.check_rounded : Icons.circle_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: widget.onRemove,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: widget.onShowInFinder,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            widget.window.asset.filename,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isLoaded)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoBadge() {
    final shouldShowHoverOverlay = _isCommandPressed && (_isHovered || widget.isSelected);
    if (widget.window.asset.type != AssetType.video || shouldShowHoverOverlay) {
      return const SizedBox.shrink();
    }

    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Align(alignment: Alignment.topCenter, child: _SerenityVideoBadge()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cornerRadius = math.min(
            _maxCardCornerRadius,
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.08,
          );
          final borderRadius = BorderRadius.circular(cornerRadius);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onOpen,
              borderRadius: borderRadius,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  boxShadow: const [BoxShadow(color: AppTheme.shadow, blurRadius: 18, offset: Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [_buildMediaPreview(), _buildVideoBadge(), _buildHoverOverlay(context)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    super.dispose();
  }
}

class _SerenityVideoBadge extends StatelessWidget {
  const _SerenityVideoBadge();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
          border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.5, vertical: 3.1),
          child: Text(
            'Video',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}

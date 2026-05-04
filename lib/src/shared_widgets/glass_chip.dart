import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_theme.dart';

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.dropTarget = false,
    this.trailing,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final bool dropTarget;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = selected || dropTarget;
    final foregroundColor = isHighlighted ? Colors.white : AppTheme.textPrimary;
    final backgroundColor = dropTarget
        ? const Color(0xFF2563EB).withValues(alpha: 0.96)
        : selected
        ? const Color(0xFF1F1E24).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.42);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 38),
              child: Padding(
                padding: EdgeInsets.fromLTRB(11, 8, trailing == null ? 11 : 8, 8),
                child: IconTheme(
                  data: IconThemeData(color: foregroundColor),
                  child: DefaultTextStyle(
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge!.copyWith(color: foregroundColor, fontWeight: FontWeight.w600),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: child),
                        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

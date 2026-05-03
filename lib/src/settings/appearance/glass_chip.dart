import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/appearance/theme.dart';

class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.child, required this.onTap, this.selected = false, this.trailing});

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: selected ? const Color(0xFF1F1E24).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.42),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 38),
              child: Padding(
                padding: EdgeInsets.fromLTRB(11, 8, trailing == null ? 11 : 8, 8),
                child: IconTheme(
                  data: IconThemeData(color: selected ? Colors.white : AppTheme.textPrimary),
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: selected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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

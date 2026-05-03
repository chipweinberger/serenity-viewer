// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellWorkspaceChrome on _SerenityShellState {
  static const double _workspaceHudGap = 10;

  Widget _buildTopChromeHitBlock() {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 84,
      child: AbsorbPointer(absorbing: true, child: ColoredBox(color: Colors.transparent)),
    );
  }

  Widget _buildWindowTitleLabel(BuildContext context) {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DefaultTextStyle(
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: SerenityTheme.textMuted, fontWeight: FontWeight.w600),
          child: Text(_windowTitle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildWorkspaceHudAction({required String tooltip, required VoidCallback? onTap, required Widget child}) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.white.withValues(alpha: 0.52),
            child: InkWell(onTap: onTap, child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChip({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
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
                  data: IconThemeData(color: selected ? Colors.white : SerenityTheme.textPrimary),
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: selected ? Colors.white : SerenityTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: child),
                        if (trailing != null) ...[const SizedBox(width: 8), trailing],
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

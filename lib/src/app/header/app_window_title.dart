import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/appearance/theme.dart';

class AppWindowTitle extends StatelessWidget {
  const AppWindowTitle({super.key, required this.windowTitle});

  final String windowTitle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DefaultTextStyle(
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
          child: Text(windowTitle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

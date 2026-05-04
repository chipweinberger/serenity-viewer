import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_root.dart';
import 'package:serenity_viewer/src/settings/appearance/theme.dart';

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppTheme.background,
      colorScheme: const ColorScheme.light(
        primary: AppTheme.accent,
        secondary: AppTheme.accentSoft,
        surface: AppTheme.panel,
      ),
      textTheme: ThemeData.light().textTheme.apply(bodyColor: AppTheme.textPrimary, displayColor: AppTheme.textPrimary),
      useMaterial3: true,
    );

    return MaterialApp(title: 'Serenity', debugShowCheckedModeBanner: false, theme: theme, home: const AppRoot());
  }
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/environment/app_environment_state.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/settings/behavior/settings_dialog.dart';
import 'package:serenity_viewer/src/video_tools/settings_and_video_models.dart';

class AppShellUiController {
  const AppShellUiController({required this.context, required this.persistenceState, required this.updateEnvironment});

  final BuildContext Function() context;
  final AppEnvironmentState persistenceState;
  final ValueChanged<Environment> updateEnvironment;

  void showAboutSerenity() {
    showAboutDialog(
      context: context(),
      applicationName: 'Serenity',
      applicationVersion: 'Desktop workspace viewer',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1D4B0), Color(0xFFD39B73), Color(0xFF8DA7D0)],
            ),
          ),
          child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
        ),
      ),
      children: const [
        SizedBox(height: 8),
        Text('Serenity is a desktop-style image and video workspace for arranging, reviewing, and revisiting media.'),
      ],
    );
  }

  Future<void> openSettings() async {
    final environment = persistenceState.environment;
    if (environment == null) {
      return;
    }

    final result = await showDialog<SettingsResult>(
      context: context(),
      builder: (context) => SettingsDialog(
        imageLoadLimit: environment.imageLoadLimit,
        shortVideoLoadLimit: environment.shortVideoLoadLimit,
        longVideoLoadLimit: environment.longVideoLoadLimit,
        knownFolders: environment.knownFolders,
        folderPopularity: environment.folderPopularity,
      ),
    );

    if (result == null) {
      return;
    }

    updateEnvironment(
      environment.copyWith(
        knownFolders: result.knownFolders,
        folderPopularity: result.folderPopularity,
        imageLoadLimit: result.imageLoadLimit,
        shortVideoLoadLimit: result.shortVideoLoadLimit,
        longVideoLoadLimit: result.longVideoLoadLimit,
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context()).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}

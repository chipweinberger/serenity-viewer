import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/session/environment_store_state.dart';
import 'package:serenity_viewer/src/settings/behavior/settings_dialog.dart';
import 'package:serenity_viewer/src/settings/behavior/settings_result.dart';

class AppSettingsController {
  const AppSettingsController({
    required this.context,
    required this.environmentStoreState,
    required this.updateEnvironment,
  });

  final BuildContext Function() context;
  final EnvironmentStoreState environmentStoreState;
  final ValueChanged<Environment> updateEnvironment;

  Future<void> openSettings() async {
    final environment = environmentStoreState.environment;
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
}

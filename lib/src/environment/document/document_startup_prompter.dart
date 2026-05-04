import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/document/document_coordinator.dart';
import 'package:serenity_viewer/src/environment/document/startup_environment_choice.dart';

Future<void> promptForStartupDocument(DocumentCoordinator coordinator) async {
  if (!coordinator.environmentStore.shouldPromptForStartupEnvironment(mounted: coordinator.mounted())) {
    return;
  }

  coordinator.environmentStore.setStartupPromptInProgress(true);
  try {
    while (coordinator.mounted() && coordinator.environmentStoreState.environment == null) {
      if (!coordinator.mounted()) {
        return;
      }

      final choice = await showDialog<StartupEnvironmentChoice>(
        context: coordinator.context(),
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Choose an environment'),
            content: const Text(
              'Serenity always works inside a .sry environment. Open an existing one or create a new one.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(StartupEnvironmentChoice.open),
                child: const Text('Open Existing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(StartupEnvironmentChoice.create),
                child: const Text('Create New'),
              ),
            ],
          );
        },
      );

      if (choice == StartupEnvironmentChoice.open) {
        final opened = await coordinator.openDocument(showSuccessMessage: false);
        if (opened) {
          return;
        }
        continue;
      }

      if (choice == StartupEnvironmentChoice.create) {
        final created = await coordinator.createDocument();
        if (created) {
          return;
        }
      }
    }
  } finally {
    coordinator.environmentStore.setStartupPromptInProgress(false);
  }
}

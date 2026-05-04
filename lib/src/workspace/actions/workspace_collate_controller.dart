import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/workspace/controllers/workspace_window_controller.dart';
import 'package:serenity_viewer/src/workspace/controllers/workspace_windows_controller.dart';

class WorkspaceCollateController {
  const WorkspaceCollateController({required this.context, required this.showMessage, required this.windowController});

  final BuildContext Function() context;
  final ValueChanged<String> showMessage;
  final WorkspaceWindowController windowController;

  Future<void> confirmCollateWorkspaceWindows() async {
    final collatableWindowCount = windowController.collatableWindowCount();
    if (collatableWindowCount == 0) {
      showMessage('There are no image or video windows to collate.');
      return;
    }

    final shouldCollate = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Collate Windows?'),
          content: Text(
            'Center and resize $collatableWindowCount image/video window'
            '${collatableWindowCount == 1 ? '' : 's'} into a fixed ${workspaceCollateTargetBox.width.toInt()} × '
            '${workspaceCollateTargetBox.height.toInt()} box?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Collate')),
          ],
        );
      },
    );

    if (shouldCollate == true) {
      windowController.collateActiveWorkspace();
    }
  }
}

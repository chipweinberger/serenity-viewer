import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';

class WorkspaceShellManagementDialogs {
  const WorkspaceShellManagementDialogs({required this.context, required this.mounted});

  final BuildContext Function() context;
  final bool Function() mounted;

  Future<String?> promptWorkspaceRename(Workspace workspace) async {
    final controller = TextEditingController(text: workspace.name);
    final nextName = await showDialog<String>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Workspace'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Workspace name'),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return nextName?.trim();
  }

  Future<bool> confirmWorkspaceDeletion(Workspace workspace) async {
    final shouldDelete = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Workspace?'),
          content: Text('Delete "${workspace.name}"? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );

    return shouldDelete == true && mounted();
  }

  Future<bool> confirmSelectedWindowMove(Workspace destinationWorkspace, int count) async {
    final noun = count == 1 ? 'window' : 'windows';
    final shouldMove = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Move Selected Windows?'),
          content: Text('Move $count selected $noun to "${destinationWorkspace.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Move')),
          ],
        );
      },
    );

    return shouldMove == true && mounted();
  }

  Future<bool> confirmTabClose(Workspace workspace) async {
    final shouldClose = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Close Tab?'),
          content: Text('This will close "${workspace.name}" in the tab bar.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Close Tab')),
          ],
        );
      },
    );

    return shouldClose == true && mounted();
  }
}

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/link.dart';

class WorkspaceLinksPrompts {
  const WorkspaceLinksPrompts({required this.context});

  final BuildContext Function() context;

  Future<bool> confirmRemoveLink({
    required Link link,
    required String Function(String value, {int maxLength}) middleTruncatedLabel,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove link?'),
          content: Text(middleTruncatedLabel(link.displayName, maxLength: 72)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
          ],
        );
      },
    );

    return shouldRemove == true;
  }

  Future<String?> promptForLinkName(Link link) async {
    final controller = TextEditingController(text: link.customName);
    final result = await showDialog<String>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Done')),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

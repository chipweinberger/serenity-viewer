import 'package:flutter/material.dart';

class WorkspaceVideoConversionPrompts {
  const WorkspaceVideoConversionPrompts({required this.context});

  final BuildContext Function() context;

  Future<bool> confirmOverwriteJpeg(String filename) async {
    final shouldOverwrite = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Replace Existing JPEG?'),
          content: Text('$filename already exists. Replace it?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Replace')),
          ],
        );
      },
    );

    return shouldOverwrite == true;
  }

  Future<bool> confirmSingleFrameConversion(String filename) async {
    final shouldConvert = await showDialog<bool>(
      context: context(),
      builder: (context) {
        return AlertDialog(
          title: const Text('Single-Frame Video Detected'),
          content: Text('$filename appears to contain a single frame. Convert it to JPEG instead?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep Video')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Convert to JPEG')),
          ],
        );
      },
    );

    return shouldConvert == true;
  }
}

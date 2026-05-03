import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/settings/appearance/theme.dart';
import 'package:serenity_viewer/src/media/conversion/settings_and_video_models.dart';

class SerenitySettingsDialog extends StatefulWidget {
  const SerenitySettingsDialog({
    super.key,
    required this.imageLoadLimit,
    required this.shortVideoLoadLimit,
    required this.longVideoLoadLimit,
    required this.knownFolders,
    required this.folderPopularity,
  });

  final int imageLoadLimit;
  final int shortVideoLoadLimit;
  final int longVideoLoadLimit;
  final List<String> knownFolders;
  final Map<String, int> folderPopularity;

  @override
  State<SerenitySettingsDialog> createState() => _SerenitySettingsDialogState();
}

class _SerenitySettingsDialogState extends State<SerenitySettingsDialog> {
  late final TextEditingController _imageController;
  late final TextEditingController _shortVideoController;
  late final TextEditingController _longVideoController;
  late List<String> _knownFolders;
  late Map<String, int> _folderPopularity;

  @override
  void initState() {
    super.initState();
    _imageController = TextEditingController(text: widget.imageLoadLimit.toString());
    _shortVideoController = TextEditingController(text: widget.shortVideoLoadLimit.toString());
    _longVideoController = TextEditingController(text: widget.longVideoLoadLimit.toString());
    _knownFolders = [...widget.knownFolders];
    _folderPopularity = Map<String, int>.from(widget.folderPopularity);
  }

  @override
  void dispose() {
    _imageController.dispose();
    _shortVideoController.dispose();
    _longVideoController.dispose();
    super.dispose();
  }

  SerenitySettingsResult _buildResult() {
    final imageLimit = int.tryParse(_imageController.text.trim());
    final shortVideoLimit = int.tryParse(_shortVideoController.text.trim());
    final longVideoLimit = int.tryParse(_longVideoController.text.trim());
    if (imageLimit == null || shortVideoLimit == null || longVideoLimit == null) {
      return SerenitySettingsResult(
        imageLoadLimit: widget.imageLoadLimit,
        shortVideoLoadLimit: widget.shortVideoLoadLimit,
        longVideoLoadLimit: widget.longVideoLoadLimit,
        knownFolders: _knownFolders,
        folderPopularity: _folderPopularity,
      );
    }

    return SerenitySettingsResult(
      imageLoadLimit: imageLimit.clamp(1, 5000),
      shortVideoLoadLimit: shortVideoLimit.clamp(1, 5000),
      longVideoLoadLimit: longVideoLimit.clamp(1, 5000),
      knownFolders: _knownFolders,
      folderPopularity: _folderPopularity,
    );
  }

  void _closeAndSave() {
    Navigator.of(context).pop(_buildResult());
  }

  Future<void> _addFolder() async {
    final path = await getDirectoryPath();
    if (!mounted || path == null || path.isEmpty) {
      return;
    }

    setState(() {
      if (!_knownFolders.contains(path)) {
        _knownFolders.add(path);
      }
      _folderPopularity[path] = (_folderPopularity[path] ?? 0) + 1;
    });
  }

  void _removeFolder(String path) {
    setState(() {
      _knownFolders.remove(path);
      _folderPopularity.remove(path);
    });
  }

  Widget _buildLimitRow({required String label, required String help, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: SerenityTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(help, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SerenityTheme.textMuted, height: 1.3)),
        const SizedBox(height: 8),
        SizedBox(
          width: 160,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.82),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: SerenityTheme.border.withValues(alpha: 0.16)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: SerenityTheme.border.withValues(alpha: 0.16)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: SerenityTheme.accent.withValues(alpha: 0.42)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedFolders = [..._knownFolders]
      ..sort((a, b) => (_folderPopularity[b] ?? 0).compareTo(_folderPopularity[a] ?? 0));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5EBD8), Color(0xFFE4D4BC)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: const [BoxShadow(color: SerenityTheme.shadow, blurRadius: 28, offset: Offset(0, 18))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maximum loaded assets',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: SerenityTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Serenity unloads assets from less recent workspaces first when these limits are reached.',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: SerenityTheme.textMuted, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _closeAndSave,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLimitRow(label: 'Images', help: 'Maximum loaded images.', controller: _imageController),
                  const SizedBox(height: 16),
                  _buildLimitRow(
                    label: 'Short videos',
                    help: 'Videos under 2 minutes.',
                    controller: _shortVideoController,
                  ),
                  const SizedBox(height: 16),
                  _buildLimitRow(
                    label: 'Long videos',
                    help: 'Videos 2 minutes or longer.',
                    controller: _longVideoController,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Known folders',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: SerenityTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Serenity searches these folders for missing files.',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: SerenityTheme.textMuted, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => unawaited(_addFolder()),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add folder'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (sortedFolders.isEmpty)
                    Text(
                      'No known folders yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SerenityTheme.textMuted),
                    )
                  else
                    for (final folder in sortedFolders)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: SerenityTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Recovery score ${_folderPopularity[folder] ?? 0}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(color: SerenityTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeFolder(folder),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Remove folder',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

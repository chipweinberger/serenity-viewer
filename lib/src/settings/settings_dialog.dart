import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/app/app_theme.dart';
import 'package:serenity_viewer/src/settings/settings_result.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.imageLoadLimit,
    required this.shortVideoLoadLimit,
    required this.longVideoLoadLimit,
    required this.autoLoadVideos,
    required this.knownFolders,
    required this.folderPopularity,
  });

  final int imageLoadLimit;
  final int shortVideoLoadLimit;
  final int longVideoLoadLimit;
  final bool autoLoadVideos;
  final List<String> knownFolders;
  final Map<String, int> folderPopularity;

  @override
  State<SettingsDialog> createState() => _SerenitySettingsDialogState();
}

class _SerenitySettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _imageController;
  late final TextEditingController _shortVideoController;
  late final TextEditingController _longVideoController;
  late final ScrollController _scrollController;
  late bool _autoLoadVideos;
  late List<String> _knownFolders;
  late Map<String, int> _folderPopularity;

  @override
  void initState() {
    super.initState();
    _imageController = TextEditingController(text: widget.imageLoadLimit.toString());
    _shortVideoController = TextEditingController(text: widget.shortVideoLoadLimit.toString());
    _longVideoController = TextEditingController(text: widget.longVideoLoadLimit.toString());
    _scrollController = ScrollController();
    _autoLoadVideos = widget.autoLoadVideos;
    _knownFolders = [...widget.knownFolders];
    _folderPopularity = Map<String, int>.from(widget.folderPopularity);
  }

  @override
  void dispose() {
    _imageController.dispose();
    _shortVideoController.dispose();
    _longVideoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  SettingsResult _buildResult() {
    final imageLimit = int.tryParse(_imageController.text.trim());
    final shortVideoLimit = int.tryParse(_shortVideoController.text.trim());
    final longVideoLimit = int.tryParse(_longVideoController.text.trim());
    if (imageLimit == null || shortVideoLimit == null || longVideoLimit == null) {
      return SettingsResult(
        imageLoadLimit: widget.imageLoadLimit,
        shortVideoLoadLimit: widget.shortVideoLoadLimit,
        longVideoLoadLimit: widget.longVideoLoadLimit,
        autoLoadVideos: _autoLoadVideos,
        knownFolders: _knownFolders,
        folderPopularity: _folderPopularity,
      );
    }

    return SettingsResult(
      imageLoadLimit: imageLimit.clamp(1, 5000),
      shortVideoLoadLimit: shortVideoLimit.clamp(1, 5000),
      longVideoLoadLimit: longVideoLimit.clamp(1, 5000),
      autoLoadVideos: _autoLoadVideos,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  if (help.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      help,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
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
                    borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.16)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.16)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.accent.withValues(alpha: 0.42)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
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
              boxShadow: const [BoxShadow(color: AppTheme.shadow, blurRadius: 28, offset: Offset(0, 18))],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 640),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
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
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'How many items stay loaded at once.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted, height: 1.35),
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
                      _buildLimitRow(label: 'Images', help: 'Of any size.', controller: _imageController),
                      const SizedBox(height: 16),
                      _buildLimitRow(
                        label: 'Short videos',
                        help: 'Under 2 minutes.',
                        controller: _shortVideoController,
                      ),
                      const SizedBox(height: 16),
                      _buildLimitRow(
                        label: 'Long videos',
                        help: '2 minutes or longer.',
                        controller: _longVideoController,
                      ),
                      const SizedBox(height: 18),
                      SwitchListTile.adaptive(
                        value: _autoLoadVideos,
                        onChanged: (value) => setState(() => _autoLoadVideos = value),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.accent,
                        title: Text(
                          'Load videos automatically',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          'Without needing to click Load videos.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Known folders'),
                                const SizedBox(height: 4),
                                Text(
                                  'Used to find missing files.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted, height: 1.3),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
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
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
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
        ),
      ),
    );
  }
}

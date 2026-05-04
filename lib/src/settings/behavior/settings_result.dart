import 'package:flutter/foundation.dart';

@immutable
class SettingsResult {
  const SettingsResult({
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
}

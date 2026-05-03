import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/environment.dart';

@immutable
class ImportResult {
  const ImportResult({
    required this.environment,
    required this.importedCount,
    required this.skippedDuplicateCount,
    required this.hadSupportedFiles,
  });

  final Environment environment;
  final int importedCount;
  final int skippedDuplicateCount;
  final bool hadSupportedFiles;
}

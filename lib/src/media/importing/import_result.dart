import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environments/session/session_state.dart';

@immutable
class SerenityImportResult {
  const SerenityImportResult({
    required this.session,
    required this.importedCount,
    required this.skippedDuplicateCount,
    required this.hadSupportedFiles,
  });

  final SerenitySessionState session;
  final int importedCount;
  final int skippedDuplicateCount;
  final bool hadSupportedFiles;
}

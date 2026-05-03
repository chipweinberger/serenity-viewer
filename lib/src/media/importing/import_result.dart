import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/sry_document/models/session_state.dart';

@immutable
class ImportResult {
  const ImportResult({
    required this.session,
    required this.importedCount,
    required this.skippedDuplicateCount,
    required this.hadSupportedFiles,
  });

  final SessionState session;
  final int importedCount;
  final int skippedDuplicateCount;
  final bool hadSupportedFiles;
}

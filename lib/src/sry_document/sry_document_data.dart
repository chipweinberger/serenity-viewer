import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/sry_document/models/session_state.dart';

@immutable
class SryDocumentData {
  const SryDocumentData({required this.session, required this.thumbnailBytesByWorkspaceId});

  final SessionState session;
  final Map<String, Uint8List> thumbnailBytesByWorkspaceId;
}

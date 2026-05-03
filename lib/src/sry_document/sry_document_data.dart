import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/environment.dart';

@immutable
class SryDocumentData {
  const SryDocumentData({required this.environment, required this.thumbnailBytesByWorkspaceId});

  final Environment environment;
  final Map<String, Uint8List> thumbnailBytesByWorkspaceId;
}

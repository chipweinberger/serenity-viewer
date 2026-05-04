import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/environment.dart';

@immutable
class DocumentData {
  const DocumentData({required this.environment, required this.thumbnailBytesByWorkspaceId});

  final Environment environment;
  final Map<String, Uint8List> thumbnailBytesByWorkspaceId;
}

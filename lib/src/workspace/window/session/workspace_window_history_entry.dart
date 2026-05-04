import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/window.dart';

@immutable
class WorkspaceWindowHistoryEntry {
  const WorkspaceWindowHistoryEntry({
    required this.workspaceId,
    required this.workspaceName,
    required this.window,
    required this.closedAt,
  });

  final String workspaceId;
  final String workspaceName;
  final Window window;
  final DateTime closedAt;
}

import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/workspace_window_state.dart';

@immutable
class RecentlyClosedWindowEntry {
  const RecentlyClosedWindowEntry({
    required this.workspaceId,
    required this.workspaceName,
    required this.window,
    required this.closedAt,
  });

  final String workspaceId;
  final String workspaceName;
  final WorkspaceWindowState window;
  final DateTime closedAt;
}

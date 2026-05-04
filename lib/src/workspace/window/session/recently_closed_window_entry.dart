import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/window.dart';

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
  final Window window;
  final DateTime closedAt;
}

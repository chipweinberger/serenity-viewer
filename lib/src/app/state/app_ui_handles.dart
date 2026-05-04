import 'package:flutter/material.dart';

class AppUiHandles {
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();
  final ScrollController tabScrollController = ScrollController();
  final Map<String, Rect> _workspaceTabBounds = {};

  void setWorkspaceTabBounds(String workspaceId, Rect bounds) {
    _workspaceTabBounds[workspaceId] = bounds;
  }

  void removeWorkspaceTabBounds(String workspaceId) {
    _workspaceTabBounds.remove(workspaceId);
  }

  String? workspaceTabAt(Offset globalPosition, {String? excludingWorkspaceId}) {
    for (final entry in _workspaceTabBounds.entries) {
      if (entry.key == excludingWorkspaceId) {
        continue;
      }
      if (entry.value.contains(globalPosition)) {
        return entry.key;
      }
    }
    return null;
  }

  void dispose() {
    _workspaceTabBounds.clear();
    tabScrollController.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}

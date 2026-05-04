import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/workspace/history/workspace_window_history_entry.dart';

class WorkspaceWindowHistoryState extends ChangeNotifier {
  final List<WorkspaceWindowHistoryEntry> _entries = [];

  List<WorkspaceWindowHistoryEntry> get entries => _entries;

  void insertClosed(WorkspaceWindowHistoryEntry entry, {required int maxEntries}) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    notifyListeners();
  }

  bool removeEntry(WorkspaceWindowHistoryEntry entry) {
    final removed = _entries.remove(entry);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }
}

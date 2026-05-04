import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/environment/history/environment_window_history_entry.dart';

class EnvironmentWindowHistoryState extends ChangeNotifier {
  final List<EnvironmentWindowHistoryEntry> _entries = [];

  List<EnvironmentWindowHistoryEntry> get entries => _entries;

  void insertClosed(EnvironmentWindowHistoryEntry entry, {required int maxEntries}) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    notifyListeners();
  }

  bool removeEntry(EnvironmentWindowHistoryEntry entry) {
    final removed = _entries.remove(entry);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }
}

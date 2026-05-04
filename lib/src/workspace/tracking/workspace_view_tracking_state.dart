import 'dart:async';

import 'package:flutter/foundation.dart';

class WorkspaceViewTrackingState extends ChangeNotifier {
  Timer? _timer;
  bool _isAppForeground = true;
  String? _candidateWorkspaceId;
  bool _countedForCurrentContext = false;

  Timer? get timer => _timer;
  bool get isAppForeground => _isAppForeground;
  String? get candidateWorkspaceId => _candidateWorkspaceId;
  bool get countedForCurrentContext => _countedForCurrentContext;

  void setAppForeground(bool value) {
    if (_isAppForeground == value) {
      return;
    }

    _isAppForeground = value;
    notifyListeners();
  }

  void replaceCandidateWorkspace(String candidateWorkspaceId) {
    _timer?.cancel();
    _timer = null;
    _candidateWorkspaceId = candidateWorkspaceId;
    _countedForCurrentContext = false;
    notifyListeners();
  }

  void setTimer(Timer? value) {
    if (identical(_timer, value)) {
      return;
    }

    _timer?.cancel();
    _timer = value;
    notifyListeners();
  }

  void markCountedForCurrentContext() {
    if (_countedForCurrentContext) {
      return;
    }

    _countedForCurrentContext = true;
    notifyListeners();
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    _candidateWorkspaceId = null;
    _countedForCurrentContext = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

class WindowWorkspaceDragState extends ChangeNotifier {
  static const Object _noChange = Object();

  String? _sourceWorkspaceId;
  String? _targetWorkspaceId;

  String? get sourceWorkspaceId => _sourceWorkspaceId;
  String? get targetWorkspaceId => _targetWorkspaceId;
  bool get isDragging => _sourceWorkspaceId != null;

  bool update({Object? sourceWorkspaceId = _noChange, Object? targetWorkspaceId = _noChange}) {
    final nextSourceWorkspaceId = sourceWorkspaceId == _noChange ? _sourceWorkspaceId : sourceWorkspaceId as String?;
    final nextTargetWorkspaceId = targetWorkspaceId == _noChange ? _targetWorkspaceId : targetWorkspaceId as String?;
    final changed = nextSourceWorkspaceId != _sourceWorkspaceId || nextTargetWorkspaceId != _targetWorkspaceId;
    if (!changed) {
      return false;
    }

    _sourceWorkspaceId = nextSourceWorkspaceId;
    _targetWorkspaceId = nextTargetWorkspaceId;
    notifyListeners();
    return true;
  }

  bool begin(String sourceWorkspaceId) {
    return update(sourceWorkspaceId: sourceWorkspaceId, targetWorkspaceId: null);
  }

  bool setTargetWorkspaceId(String? workspaceId) {
    return update(targetWorkspaceId: workspaceId);
  }

  bool end() {
    return update(sourceWorkspaceId: null, targetWorkspaceId: null);
  }
}

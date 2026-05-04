import 'package:flutter/foundation.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';

class AppUiState extends ChangeNotifier {
  static const Object _noChange = Object();

  SerenityScreen _screen = SerenityScreen.workspace;
  WorkspaceLayoutMode _workspaceLayoutMode = WorkspaceLayoutMode.freeform;
  WorkspaceSort _workspaceSort = WorkspaceSort.recentlyViewed;
  bool _editMode = false;
  bool _isDropTargetActive = false;
  String? _draggingTabWorkspaceId;

  SerenityScreen get screen => _screen;
  WorkspaceLayoutMode get workspaceLayoutMode => _workspaceLayoutMode;
  WorkspaceSort get workspaceSort => _workspaceSort;
  bool get editMode => _editMode;
  bool get isDropTargetActive => _isDropTargetActive;
  String? get draggingTabWorkspaceId => _draggingTabWorkspaceId;

  bool update({
    SerenityScreen? screen,
    WorkspaceLayoutMode? workspaceLayoutMode,
    WorkspaceSort? workspaceSort,
    bool? editMode,
    bool? isDropTargetActive,
    Object? draggingTabWorkspaceId = _noChange,
  }) {
    final nextScreen = screen ?? _screen;
    final nextWorkspaceLayoutMode = workspaceLayoutMode ?? _workspaceLayoutMode;
    final nextWorkspaceSort = workspaceSort ?? _workspaceSort;
    final nextEditMode = editMode ?? _editMode;
    final nextIsDropTargetActive = isDropTargetActive ?? _isDropTargetActive;
    final nextDraggingTabWorkspaceId = draggingTabWorkspaceId == _noChange
        ? _draggingTabWorkspaceId
        : draggingTabWorkspaceId as String?;
    final changed =
        nextScreen != _screen ||
        nextWorkspaceLayoutMode != _workspaceLayoutMode ||
        nextWorkspaceSort != _workspaceSort ||
        nextEditMode != _editMode ||
        nextIsDropTargetActive != _isDropTargetActive ||
        nextDraggingTabWorkspaceId != _draggingTabWorkspaceId;
    if (!changed) {
      return false;
    }

    _screen = nextScreen;
    _workspaceLayoutMode = nextWorkspaceLayoutMode;
    _workspaceSort = nextWorkspaceSort;
    _editMode = nextEditMode;
    _isDropTargetActive = nextIsDropTargetActive;
    _draggingTabWorkspaceId = nextDraggingTabWorkspaceId;
    notifyListeners();
    return true;
  }

  bool showWorkspaceScreenDefaults() {
    return update(screen: SerenityScreen.workspace, workspaceLayoutMode: WorkspaceLayoutMode.freeform, editMode: false);
  }

  bool setDraggingTabWorkspaceId(String? workspaceId) {
    return update(draggingTabWorkspaceId: workspaceId);
  }

  bool setWorkspaceSort(WorkspaceSort sort) {
    return update(workspaceSort: sort);
  }

  bool setDropTargetActive(bool isActive) {
    return update(isDropTargetActive: isActive);
  }
}

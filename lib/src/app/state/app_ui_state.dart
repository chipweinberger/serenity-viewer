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
  String? _windowDragTargetWorkspaceId;
  String? _draggingWindowSourceWorkspaceId;
  final List<int> _activeWorkspaceImportAssetCounts = [];

  SerenityScreen get screen => _screen;
  WorkspaceLayoutMode get workspaceLayoutMode => _workspaceLayoutMode;
  WorkspaceSort get workspaceSort => _workspaceSort;
  bool get editMode => _editMode;
  bool get isDropTargetActive => _isDropTargetActive;
  String? get draggingTabWorkspaceId => _draggingTabWorkspaceId;
  String? get windowDragTargetWorkspaceId => _windowDragTargetWorkspaceId;
  String? get draggingWindowSourceWorkspaceId => _draggingWindowSourceWorkspaceId;
  bool get isWorkspaceImporting => _activeWorkspaceImportAssetCounts.isNotEmpty;
  int get workspaceImportAssetCount =>
      _activeWorkspaceImportAssetCounts.fold<int>(0, (currentMax, count) => count > currentMax ? count : currentMax);

  bool update({
    SerenityScreen? screen,
    WorkspaceLayoutMode? workspaceLayoutMode,
    WorkspaceSort? workspaceSort,
    bool? editMode,
    bool? isDropTargetActive,
    Object? draggingTabWorkspaceId = _noChange,
    Object? windowDragTargetWorkspaceId = _noChange,
    Object? draggingWindowSourceWorkspaceId = _noChange,
  }) {
    final nextScreen = screen ?? _screen;
    final nextWorkspaceLayoutMode = workspaceLayoutMode ?? _workspaceLayoutMode;
    final nextWorkspaceSort = workspaceSort ?? _workspaceSort;
    final nextEditMode = editMode ?? _editMode;
    final nextIsDropTargetActive = isDropTargetActive ?? _isDropTargetActive;
    final nextDraggingTabWorkspaceId = draggingTabWorkspaceId == _noChange
        ? _draggingTabWorkspaceId
        : draggingTabWorkspaceId as String?;
    final nextWindowDragTargetWorkspaceId = windowDragTargetWorkspaceId == _noChange
        ? _windowDragTargetWorkspaceId
        : windowDragTargetWorkspaceId as String?;
    final nextDraggingWindowSourceWorkspaceId = draggingWindowSourceWorkspaceId == _noChange
        ? _draggingWindowSourceWorkspaceId
        : draggingWindowSourceWorkspaceId as String?;
    final changed =
        nextScreen != _screen ||
        nextWorkspaceLayoutMode != _workspaceLayoutMode ||
        nextWorkspaceSort != _workspaceSort ||
        nextEditMode != _editMode ||
        nextIsDropTargetActive != _isDropTargetActive ||
        nextDraggingTabWorkspaceId != _draggingTabWorkspaceId ||
        nextWindowDragTargetWorkspaceId != _windowDragTargetWorkspaceId ||
        nextDraggingWindowSourceWorkspaceId != _draggingWindowSourceWorkspaceId;
    if (!changed) {
      return false;
    }

    _screen = nextScreen;
    _workspaceLayoutMode = nextWorkspaceLayoutMode;
    _workspaceSort = nextWorkspaceSort;
    _editMode = nextEditMode;
    _isDropTargetActive = nextIsDropTargetActive;
    _draggingTabWorkspaceId = nextDraggingTabWorkspaceId;
    _windowDragTargetWorkspaceId = nextWindowDragTargetWorkspaceId;
    _draggingWindowSourceWorkspaceId = nextDraggingWindowSourceWorkspaceId;
    notifyListeners();
    return true;
  }

  bool showWorkspaceScreenDefaults() {
    return update(screen: SerenityScreen.workspace, workspaceLayoutMode: WorkspaceLayoutMode.freeform, editMode: false);
  }

  bool setDraggingTabWorkspaceId(String? workspaceId) {
    return update(draggingTabWorkspaceId: workspaceId);
  }

  bool setWindowDragTargetWorkspaceId(String? workspaceId) {
    return update(windowDragTargetWorkspaceId: workspaceId);
  }

  bool setDraggingWindowSourceWorkspaceId(String? workspaceId) {
    return update(draggingWindowSourceWorkspaceId: workspaceId);
  }

  bool setWorkspaceSort(WorkspaceSort sort) {
    return update(workspaceSort: sort);
  }

  bool setDropTargetActive(bool isActive) {
    return update(isDropTargetActive: isActive);
  }

  void beginWorkspaceImport(int assetCount) {
    if (assetCount <= 0) {
      return;
    }

    _activeWorkspaceImportAssetCounts.add(assetCount);
    notifyListeners();
  }

  void endWorkspaceImport(int assetCount) {
    if (assetCount <= 0) {
      return;
    }

    final index = _activeWorkspaceImportAssetCounts.indexOf(assetCount);
    if (index < 0) {
      return;
    }

    _activeWorkspaceImportAssetCounts.removeAt(index);
    notifyListeners();
  }
}

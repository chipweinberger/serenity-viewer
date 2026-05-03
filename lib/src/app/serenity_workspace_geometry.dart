// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellWorkspaceGeometry on _SerenityShellState {
  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(9999)}';
  }

  int _colorFromDigest(String value) {
    return assetColorFromMd5(value).toARGB32();
  }

  double _clampWorkspaceZoom(double zoom) {
    return SerenityWorkspaceMutations.clampWorkspaceZoom(zoom);
  }

  void _setWorkspaceViewport({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) {
    final session = _persistenceState.session;
    if (session == null) {
      return;
    }

    final workspaceMatches = session.workspaces.where((workspace) => workspace.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final nextWorkspace = SerenityWorkspaceMutations.setWorkspaceViewport(
      workspace,
      viewportSize: _workspaceViewportState.viewportSize,
      center: center,
      zoom: zoom,
    );
    final viewportChanged =
        (workspace.viewportCenter.dx - nextWorkspace.viewportCenter.dx).abs() > 0.001 ||
        (workspace.viewportCenter.dy - nextWorkspace.viewportCenter.dy).abs() > 0.001 ||
        (workspace.viewportZoom - nextWorkspace.viewportZoom).abs() > 0.001;
    if (!viewportChanged) {
      return;
    }

    _replaceWorkspace(nextWorkspace, queueThumbnail: queueThumbnail);
    if (!queueThumbnail) {
      _thumbnailRefreshState.dirtyWorkspaces.add(workspaceId);
    }
  }

  Offset _clampWindowPosition(Offset position, Size size) {
    return SerenityWorkspaceMutations.clampWindowPosition(position, size);
  }
}

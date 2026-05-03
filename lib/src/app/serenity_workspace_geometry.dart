// ignore_for_file: invalid_use_of_protected_member

part of 'serenity_shell.dart';

extension _SerenityShellWorkspaceGeometry on _SerenityShellState {
  AssetType? _assetTypeForPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (_SerenityShellState._imageExtensions.contains(extension)) {
      return AssetType.image;
    }
    if (_SerenityShellState._videoExtensions.contains(extension)) {
      return AssetType.video;
    }
    return null;
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(9999)}';
  }

  int _colorFromDigest(String value) {
    return assetColorFromMd5(value).toARGB32();
  }

  double _clampWorkspaceZoom(double zoom) {
    return SerenityWorkspaceMutations.clampWorkspaceZoom(zoom);
  }

  Offset _clampWorkspaceCenter({required Offset center, required double zoom, required Size viewportSize}) {
    return SerenityWorkspaceMutations.clampWorkspaceCenter(center: center, zoom: zoom, viewportSize: viewportSize);
  }

  void _setWorkspaceViewport({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) {
    final session = _session;
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
